import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_client_factory.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/analytics/posthog_mobile_client.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:posthog_flutter/src/posthog_flutter_platform_interface.dart';

/// The SDK's platform side, recording what the app asks of it.
class _FakePlatform extends PosthogFlutterPlatformInterface
    with MockPlatformInterfaceMixin {
  final calls = <String>[];
  PostHogConfig? config;
  Completer<void>? setupGate;
  Object? setupError;
  final registered = <String, Object>{};

  @override
  Future<void> setup(PostHogConfig config) async {
    calls.add('setup');
    this.config = config;
    await setupGate?.future;
    final error = setupError;
    if (error != null) throw error;
  }

  @override
  Future<void> enable() async => calls.add('enable');

  @override
  Future<void> disable() async => calls.add('disable');

  @override
  Future<void> reset() async {
    // The SDK forgets what it was told when it is reset.
    registered.clear();
    calls.add('reset');
  }

  @override
  Future<void> register(String key, Object value) async {
    registered[key] = value;
    calls.add('register $key');
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async =>
      calls.add('identify $userId');

  @override
  Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async =>
      calls.add('capture $eventName ${properties ?? {}}');

  @override
  Future<void> screen({
    required String screenName,
    Map<String, Object>? properties,
  }) async =>
      calls.add('screen $screenName ${properties ?? {}}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePlatform platform;
  late PosthogMobileClient client;
  final original = PosthogFlutterPlatformInterface.instance;

  setUp(() {
    platform = _FakePlatform();
    PosthogFlutterPlatformInterface.instance = platform;
    client = PosthogMobileClient(
      apiKey: 'phc_test',
      host: 'https://eu.i.posthog.com',
      environment: 'staging',
    );
  });

  tearDown(() {
    PosthogFlutterPlatformInterface.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });

  test('is available and sends nothing before it is started', () async {
    expect(client.isAvailable, isTrue);

    client.capture('setoran_disimpan', {'berhasil': true});
    client.screen('Dashboard');
    client.identify('42');
    client.register({'peran': 'pengurus'});
    client.reset();
    await client.stop();

    expect(platform.calls, isEmpty);
  });

  test(
      'starting sets the SDK up with everything automatic off but the masked '
      'recording', () async {
    await client.start();

    final config = platform.config!;
    expect(config.projectToken, 'phc_test');
    expect(config.host, 'https://eu.i.posthog.com');
    // The screen is recorded, with every text and image hidden.
    expect(config.sessionReplay, isTrue);
    expect(config.sessionReplayConfig.maskAllTexts, isTrue);
    expect(config.sessionReplayConfig.maskAllImages, isTrue);
    expect(config.captureApplicationLifecycleEvents, isFalse);
    expect(config.surveys, isFalse);
    expect(config.preloadFeatureFlags, isFalse);
    expect(config.capturePushNotificationSubscriptions, isFalse);
    expect(config.capturePushNotificationOpened, isFalse);
    expect(config.debug, isFalse);
    expect(config.errorTrackingConfig.captureFlutterErrors, isFalse);
    expect(config.errorTrackingConfig.captureNativeExceptions, isFalse);
    // Opted out until start() has agreed, then switched on.
    expect(config.optOut, isTrue);
    expect(platform.calls.first, 'setup');
    expect(platform.calls, contains('enable'));
    expect(
        platform.registered, {'platform': 'android', 'environment': 'staging'});
  });

  test('signing out and in again tells the SDK where this runs once more',
      () async {
    await client.start();
    await client.stop();
    client.reset();
    expect(platform.registered, isEmpty);

    await client.start();

    expect(
        platform.registered, {'platform': 'android', 'environment': 'staging'});
  });

  test('an iPhone says it is one', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await client.start();

    expect(platform.registered['platform'], 'ios');
  });

  test('the recorder is only put around the app once the SDK is set up',
      () async {
    const app = SizedBox();

    expect(client.recordsScreen, isTrue);
    expect(client.wrapApp(app), same(app));

    await client.start();

    final wrapped = client.wrapApp(app);
    expect(wrapped, isA<PostHogWidget>());
    expect((wrapped as PostHogWidget).child, same(app));
  });

  test('a second start does not set the SDK up again', () async {
    await client.start();
    await client.start();

    expect(platform.calls.where((c) => c == 'setup'), hasLength(1));
  });

  test('events, screens, ids and properties pass through once started',
      () async {
    await client.start();
    platform.calls.clear();

    client.capture('setoran_disimpan', {'berhasil': true, 'jumlah_item': null});
    client.screen('Dashboard', {'dari': 'Login'});
    client.identify('42');
    client.register({'peran': 'pengurus'});

    expect(platform.calls, [
      'capture setoran_disimpan {berhasil: true}',
      'screen Dashboard {dari: Login}',
      'identify 42',
      'register peran',
    ]);
  });

  test('stopping opts out and silences everything', () async {
    await client.start();
    await client.stop();
    platform.calls.clear();

    client.capture('setoran_disimpan');
    client.screen('Dashboard');
    client.identify('42');
    client.register({'peran': 'pengurus'});

    expect(platform.calls, isEmpty);
    await client.stop();
  });

  test('forgetting the user still works after a stop', () async {
    await client.start();
    await client.stop();

    client.reset();

    expect(platform.calls.last, 'reset');
  });

  test('starting again after a stop opts back in', () async {
    await client.start();
    await client.stop();
    platform.calls.clear();

    await client.start();
    client.capture('setoran_disimpan');

    expect(platform.calls.first, 'enable');
    expect(platform.calls.last, startsWith('capture setoran_disimpan'));
  });

  test('a stop during setup wins over the start that was waiting', () async {
    platform.setupGate = Completer<void>();
    final starting = client.start();
    final stopping = client.stop();
    platform.setupGate!.complete();
    await Future.wait([starting, stopping]);

    client.capture('setoran_disimpan');

    expect(platform.calls, isNot(contains('enable')));
    expect(platform.calls.where((c) => c.startsWith('capture')), isEmpty);
    expect(platform.calls, contains('disable'));
  });

  test('a stop that comes while enabling is not undone', () async {
    await client.start();
    await client.stop();
    final starting = client.start();
    await client.stop();
    await starting;

    client.capture('setoran_disimpan');

    expect(platform.calls.where((c) => c.startsWith('capture')), isEmpty);
  });

  test('a failed setup is reported and tried again next time', () async {
    platform.setupError = StateError('no native side');
    await expectLater(client.start(), throwsStateError);
    // Withdrawing consent after a failed start must still work.
    await client.stop();

    platform.setupError = null;
    await client.start();
    client.capture('setoran_disimpan');

    expect(platform.calls.where((c) => c == 'setup'), hasLength(2));
    expect(platform.calls.last, startsWith('capture setoran_disimpan'));
  });

  group('the client the build gets', () {
    const config = AnalyticsConfig(
      apiKey: 'phc_test',
      host: 'https://eu.i.posthog.com',
      environment: 'staging',
    );

    test('on Android and iOS it is PostHog', () {
      for (final target in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = target;
        expect(createAnalyticsClient(config), isA<PosthogMobileClient>());
      }
    });

    test('an unconfigured build and other platforms stay off', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(createAnalyticsClient(null), isA<NoopAnalyticsClient>());

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(createAnalyticsClient(config), isA<NoopAnalyticsClient>());
    });
  });
}
