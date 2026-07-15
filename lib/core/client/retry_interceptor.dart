import 'package:dio/dio.dart';

/// Retries a dropped GET exactly once, after a short delay.
///
/// A request can die after the socket is established — a pooled keep-alive
/// connection reused just as the server closes it, say — and the same call then
/// succeeds immediately afterwards. Without this, that reaches the UI as a
/// genuine error: the dashboard's transaksi fetch failing while the backend is
/// perfectly healthy.
///
/// ## Why this triggers on shape rather than exception class
///
/// It is tempting to match the specific errors seen in the wild
/// (`SocketException` and friends). Don't. A post-connect failure surfaces as
/// whatever the transport happened to throw — `HttpException: Connection closed
/// before full header was received` is common, but it is not the only one — and
/// Dio funnels every non-Dio error into [DioExceptionType.unknown] via
/// `assureDioException`, discarding the distinction. An earlier version of this
/// class gated on `err.error is SocketException` and silently never fired,
/// because the real failure was an `HttpException`.
///
/// So the trigger is the *shape* of the failure instead: a GET that came back
/// with no response at all. That is decidable, covers every transport error at
/// once, and stays correct for the next exception class nobody predicted.
///
/// ## Why these limits are safety-critical
///
/// - **GET only.** A dropped POST/PUT/PATCH/DELETE may well have reached the
///   server before the connection died, so replaying it risks duplicating a
///   write (a second transaksi, say). Those are left to fail so the user can
///   decide to retry.
/// - **No response only.** A 4xx/5xx means the server did answer; that is a real
///   error, not a drop, and retrying it would only double the load.
/// - **[DioExceptionType.unknown] / [DioExceptionType.connectionError] only.**
///   A `cancel` was deliberate, and the timeout types already waited their full
///   budget — retrying those would double a stall the user is sitting through.
class RetryInterceptor extends Interceptor {
  /// Long enough for a racing connection to be replaced by a fresh one, short
  /// enough that a user waiting on a cold-start fetch doesn't notice it.
  static const retryDelay = Duration(milliseconds: 300);

  /// Failures where the request never reached, or never got an answer from, the
  /// server. Deliberate cancellations and exhausted timeouts are excluded.
  static const retryableTypes = {
    DioExceptionType.unknown,
    DioExceptionType.connectionError,
  };

  /// Marks a request as already retried. Lives on `RequestOptions.extra`, which
  /// [Dio.fetch] carries through the replay, so the retried attempt reaches this
  /// interceptor again but declines to retry a second time.
  static const retriedFlag = 'retried_after_connection_drop';

  final Dio dio;

  RetryInterceptor(this.dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isRetryableDrop(err)) return handler.next(err);

    final options = err.requestOptions;
    options.extra[retriedFlag] = true;
    await Future<void>.delayed(retryDelay);

    try {
      return handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      // The retry failed too — surface that failure, not the original.
      return handler.next(retryError);
    }
  }

  bool _isRetryableDrop(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    if (err.requestOptions.extra[retriedFlag] == true) return false;
    if (err.response != null) return false;

    return retryableTypes.contains(err.type);
  }
}
