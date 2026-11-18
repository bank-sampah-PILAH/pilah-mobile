import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';

@module
abstract class ErrorModule {
  /// Errors only leave the app while the pengurus has agreed to analytics, and
  /// only the ones worth telling the team about. The last link, the one that
  /// talks to a monitoring service, depends on the platform.
  @lazySingleton
  ErrorReporter errorReporter(AnalyticsClient analytics) =>
      ConsentGatedErrorReporter(
        analytics: analytics,
        inner: FilteredErrorReporter(inner: createPlatformErrorReporter()),
      );
}
