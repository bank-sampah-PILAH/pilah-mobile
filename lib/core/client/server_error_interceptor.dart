import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

/// Tells the team about every answer of 500 or more, at the place it arrives.
///
/// Most screens catch a failed call and show "Coba Lagi", so the error never
/// reaches the global handlers and would go unseen. Reporting never changes
/// what the caller gets (the reporter must not throw: the one in the graph is
/// wrapped in a `SafeErrorReporter`), and the same failure reported again higher
/// up is dropped by `DeduplicatingErrorReporter`.
class ServerErrorInterceptor extends Interceptor {
  ServerErrorInterceptor(this.reporter);

  final ErrorReporter reporter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if ((err.response?.statusCode ?? 0) >= 500) {
      reporter.report(err, err.stackTrace);
    }
    handler.next(err);
  }
}
