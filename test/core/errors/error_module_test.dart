import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_module.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:posthog_flutter/src/posthog_flutter_platform_interface.dart';

import '../../support/fake_analytics_client.dart';

class _Module extends ErrorModule {}

class _FakePlatform extends PosthogFlutterPlatformInterface
    with MockPlatformInterfaceMixin {
  final captured = <Map<String, Object>?>[];

  @override
  Future<void> captureException({
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object>? properties,
  }) async =>
      captured.add(properties);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = PosthogFlutterPlatformInterface.instance;
  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform();
    PosthogFlutterPlatformInterface.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    PosthogFlutterPlatformInterface.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });

  group('ErrorModule.errorReporter', () {
    test('sends an error once analytics is recording, and not before',
        () async {
      final analytics = FakeAnalyticsClient();
      final reporter = _Module().errorReporter(analytics);

      reporter.report(StateError('before consent'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);
      expect(platform.captured, isEmpty);

      await analytics.start();
      reporter.report(StateError('after consent'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);
      expect(platform.captured, hasLength(1));
    });
  });

  group('AppRouterConfig.currentPath', () {
    test('is null before the router has shown a page', () {
      expect(AppRouterConfig.currentPath(), isNull);
    });
  });
}
