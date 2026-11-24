import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_screen_tracker.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';

@module
abstract class ErrorModule {
  /// Errors only leave the app while the pengurus has agreed to analytics, and
  /// only the ones worth telling the team about. The last link, the one that
  /// talks to a monitoring service, depends on the platform.
  @lazySingleton
  ErrorReporter errorReporter(AnalyticsClient analytics) =>
      ConsentGatedErrorReporter(
        allowed: () => analytics.isRecording,
        inner: FilteredErrorReporter(
          inner: ContextualErrorReporter(
            inner: createPlatformErrorReporter(),
            currentScreen: _currentScreen,
          ),
        ),
      );

  /// The screen showing now, named like analytics names it, or null before the
  /// router exists or has a page.
  static String? _currentScreen() {
    try {
      final shown =
          AppRouterConfig.getRouter().routerDelegate.currentConfiguration;
      return shown.isEmpty
          ? null
          : AnalyticsScreenTracker.nameFor(shown.fullPath);
    } catch (_) {
      return null;
    }
  }
}
