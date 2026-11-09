import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    as core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart'
    as messaging;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/notifications/firebase_push.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/core/utils/firebase_initialization.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../support/stub_api.dart';

class _FirebaseCore extends core.FirebasePlatform {
  final platformApp = core.FirebaseAppPlatform(
    core.defaultFirebaseAppName,
    const FirebaseOptions(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
    ),
  );
  bool hasApp = false;
  FirebaseOptions? initializedOptions;

  @override
  List<core.FirebaseAppPlatform> get apps => hasApp ? [platformApp] : [];

  @override
  core.FirebaseAppPlatform app([String name = core.defaultFirebaseAppName]) =>
      platformApp;

  @override
  Future<core.FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    initializedOptions = options;
    hasApp = true;
    return platformApp;
  }
}

class _FirebaseMessaging extends messaging.FirebaseMessagingPlatform {
  final refresh = StreamController<String>.broadcast();
  final vapidKeys = <String?>[];
  int permissionRequests = 0;
  bool tokenDeleted = false;
  String token = 'device-token';
  RemoteMessage? initialMessage;

  @override
  messaging.FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) =>
      this;

  @override
  messaging.FirebaseMessagingPlatform setInitialValues(
          {bool? isAutoInitEnabled}) =>
      this;

  @override
  Future<messaging.NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionRequests++;
    return const messaging.NotificationSettings(
      alert: messaging.AppleNotificationSetting.enabled,
      announcement: messaging.AppleNotificationSetting.disabled,
      authorizationStatus: messaging.AuthorizationStatus.authorized,
      badge: messaging.AppleNotificationSetting.enabled,
      carPlay: messaging.AppleNotificationSetting.disabled,
      lockScreen: messaging.AppleNotificationSetting.enabled,
      notificationCenter: messaging.AppleNotificationSetting.enabled,
      showPreviews: messaging.AppleShowPreviewSetting.always,
      timeSensitive: messaging.AppleNotificationSetting.disabled,
      criticalAlert: messaging.AppleNotificationSetting.disabled,
      sound: messaging.AppleNotificationSetting.enabled,
      providesAppNotificationSettings:
          messaging.AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    vapidKeys.add(vapidKey);
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> deleteToken() async {
    tokenDeleted = true;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;
}

class _MockAuthenticationUseCases extends Mock
    implements AuthenticationUseCases {}

class _MockLoginWithGoogleUseCase extends Mock
    implements LoginWithGoogleUseCase {}

final _firebaseCore = _FirebaseCore();
final _firebaseMessaging = _FirebaseMessaging();

void main() {
  late core.FirebasePlatform? previousFirebaseCore;
  late messaging.FirebaseMessagingPlatform previousFirebaseMessaging;

  setUpAll(() {
    previousFirebaseCore = Firebase.delegatePackingProperty;
    previousFirebaseMessaging = messaging.FirebaseMessagingPlatform.instance;
    Firebase.delegatePackingProperty = _firebaseCore;
    messaging.FirebaseMessagingPlatform.instance = _firebaseMessaging;
  });

  setUp(() {
    _firebaseCore.hasApp = false;
    _firebaseCore.initializedOptions = null;
    _firebaseMessaging.permissionRequests = 0;
    _firebaseMessaging.tokenDeleted = false;
    _firebaseMessaging.initialMessage = null;
    _firebaseMessaging.vapidKeys.clear();
  });

  tearDownAll(() async {
    Firebase.delegatePackingProperty = previousFirebaseCore;
    messaging.FirebaseMessagingPlatform.instance = previousFirebaseMessaging;
    await _firebaseMessaging.refresh.close();
  });

  test('initializes configured web Firebase and leaves native options null',
      () async {
    const environment = {
      'FIREBASE_WEB_API_KEY': 'web-api-key',
      'FIREBASE_WEB_APP_ID': 'web-app-id',
      'FIREBASE_MESSAGING_SENDER_ID': 'web-sender-id',
      'FIREBASE_PROJECT_ID': 'web-project-id',
    };
    expect(firebaseWebConfigured(environment), isTrue);
    expect(firebaseWebConfigured({'FIREBASE_WEB_APP_ID': ''}), isFalse);
    expect(firebaseWebConfigured(const {}), isFalse);

    await initializeFirebaseForEnvironment(environment, isWeb: true);

    expect(_firebaseCore.initializedOptions?.apiKey, 'web-api-key');
    expect(_firebaseCore.initializedOptions?.appId, 'web-app-id');
    expect(
        _firebaseCore.initializedOptions?.messagingSenderId, 'web-sender-id');
    expect(_firebaseCore.initializedOptions?.projectId, 'web-project-id');

    _firebaseCore.hasApp = false;
    await initializeFirebaseForEnvironment(environment, isWeb: false);
    expect(_firebaseCore.initializedOptions, isNull);
  });

  test('skips push setup when Firebase has no app', () async {
    final api = StubApi();
    final session = createPushSession(api.network);

    expect(createPushPresentation(), isNull);
    await session.start();
    await session.stop();

    expect(api.requests, isEmpty);
    expect(_firebaseMessaging.permissionRequests, 0);
    expect(_firebaseMessaging.tokenDeleted, isFalse);
  });

  test('registers and removes the Firebase device token', () async {
    _firebaseCore.hasApp = true;
    final api = StubApi();
    api.on('POST', '/api/v1/device-tokens/', json: {});
    api.on('DELETE', '/api/v1/device-tokens/', json: {});
    final session = createPushSession(api.network);

    await session.start();
    await session.stop();

    expect(_firebaseMessaging.permissionRequests, 1);
    expect(_firebaseMessaging.vapidKeys, [null]);
    expect(api.requests.map((request) => request.method), ['POST', 'DELETE']);
    expect(api.requests.map((request) => request.json['token']),
        ['device-token', 'device-token']);
    expect(api.requests.map((request) => request.json['platform']),
        ['android', null]);
    expect(_firebaseMessaging.tokenDeleted, isTrue);
  });

  testWidgets('opens history on taps and shows foreground notifications',
      (tester) async {
    _firebaseCore.hasApp = true;
    _firebaseMessaging.initialMessage = RemoteMessage(messageId: 'initial');
    final api = StubApi();
    api.on('GET', '/api/v1/notifications/', json: []);
    di.registerSingleton<NetworkService>(api.network);
    addTearDown(() => di.unregister<NetworkService>());

    await tester.pumpWidget(MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: const Scaffold(body: Text('Home'))));
    final presentation = createPushPresentation()!;
    addTearDown(presentation.stop);
    await presentation.start();
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    expect(rootNavigatorKey.currentContext, isNotNull);
    expect(
        ScaffoldMessenger.maybeOf(rootNavigatorKey.currentContext!), isNotNull);

    presentation.show(RemoteMessage());
    await tester.pump();
    await tester.pump();
    expect(find.text('Lihat'), findsNothing);

    presentation.show(RemoteMessage(
      notification: RemoteNotification(
        title: 'Jadwal baru',
        body: 'Ada jadwal baru.',
      ),
    ));
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Jadwal baru\nAda jadwal baru.'), findsOneWidget);
    expect(find.text('Lihat'), findsOneWidget);
    await tester.tap(find.text('Lihat'));
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi.'), findsOneWidget);

    expect(api.requests.where((request) => request.method == 'GET').length, 2);
  });

  test('the production provider constructs push services from the container',
      () {
    final api = StubApi();
    di.registerSingleton<AuthenticationUseCases>(_MockAuthenticationUseCases());
    di.registerSingleton<LoginWithGoogleUseCase>(_MockLoginWithGoogleUseCase());
    di.registerSingleton<NetworkService>(api.network);
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      await di.reset();
    });

    expect(
        container.read(authenticationProvider), isA<AuthenticationInitial>());
  });
}
