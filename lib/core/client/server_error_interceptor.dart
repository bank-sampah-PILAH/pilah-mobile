import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

/// Tells the team about every answer of 500 or more, at the place it arrives.
///
/// Most screens catch a failed call and show "Coba Lagi", so the error never
/// reaches the global handlers and would go unseen. The reporter is asked for
/// lazily: it needs analytics, which is built after the network layer.
/// Reporting never changes what the caller gets, and the same failure reported
/// again higher up is dropped by `DeduplicatingErrorReporter`.
class ServerErrorInterceptor extends Interceptor {
  ServerErrorInterceptor(this.reporter);

  final ErrorReporter Function() reporter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if ((err.response?.statusCode ?? 0) >= 500) {
      try {
        reporter().report(err, err.stackTrace);
      } catch (_) {
        // A failure to report must not disturb the call.
      }
    }
    handler.next(err);
  }
}
