import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/posthog_mobile_error_reporter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:posthog_flutter/src/posthog_flutter_platform_interface.dart';

class _FakePlatform extends PosthogFlutterPlatformInterface
    with MockPlatformInterfaceMixin {
  final captured =
      <({Object error, StackTrace? stack, Map<String, Object>? properties})>[];
  Object? failWith;

  @override
  Future<void> captureException({
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object>? properties,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    captured.add((error: error, stack: stackTrace, properties: properties));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePlatform platform;
  final original = PosthogFlutterPlatformInterface.instance;

  setUp(() {
    platform = _FakePlatform();
    PosthogFlutterPlatformInterface.instance = platform;
  });

  tearDown(() => PosthogFlutterPlatformInterface.instance = original);

  group('PosthogMobileErrorReporter', () {
    test('hands the error, its stack and the context to the SDK', () async {
      final error = StateError('boom');
      final stack = StackTrace.current;

      PosthogMobileErrorReporter().report(
        error,
        stack,
        context: {'layar': 'setoran_baru'},
      );
      await Future<void>.delayed(Duration.zero);

      final sent = platform.captured.single;
      expect(sent.error, error);
      expect(sent.stack, stack);
      expect(sent.properties, {'layar': 'setoran_baru'});
    });

    test('reports an error nobody caught as not handled, without the marker',
        () async {
      final error = StateError('boom');

      PosthogMobileErrorReporter().report(
        error,
        StackTrace.current,
        context: {'layar': 'setoran_baru', 'ditangani': false},
      );
      await Future<void>.delayed(Duration.zero);

      final sent = platform.captured.single;
      // The SDK wraps it to say how it was caught: it is the only way to set
      // the flag, and the wrapper is not exported.
      expect((sent.error as dynamic).handled, isFalse);
      expect((sent.error as dynamic).source, error);
      expect(sent.properties, {'layar': 'setoran_baru'});
    });

    test('a failing SDK never disturbs the app', () async {
      platform.failWith = StateError('the SDK is not set up');
      final uncaught = <Object>[];

      runZonedGuarded(() {
        PosthogMobileErrorReporter()
            .report(StateError('x'), StackTrace.current);
      }, (error, _) => uncaught.add(error));
      await Future<void>.delayed(Duration.zero);

      expect(uncaught, isEmpty);
    });
  });
}
