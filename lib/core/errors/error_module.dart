import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

@module
abstract class ErrorModule {
  /// Errors only leave the app while the pengurus has agreed to analytics, and
  /// only the ones worth telling the team about. The last link, the one that
  /// talks to a monitoring service, is a no-op until a platform provides one.
  @lazySingleton
  ErrorReporter errorReporter(AnalyticsClient analytics) =>
      ConsentGatedErrorReporter(
        analytics: analytics,
        inner: FilteredErrorReporter(inner: const NoopErrorReporter()),
      );
}
