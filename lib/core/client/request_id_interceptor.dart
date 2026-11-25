import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/utils/uuid_v4.dart';

/// The header that carries a request's id.
///
/// The backend has to list it in `CORS_ALLOW_HEADERS` before a browser may send
/// it: a custom header that is not listed fails the preflight of every call.
const requestIdHeader = 'X-Request-Id';

/// Gives every request a random id, so a failure the user saw can be found in
/// the server's log, and the server's error can be found from the user's report.
///
/// The id is random and names nobody. A request that already has one (a retry
/// of the same call) keeps it.
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(requestIdHeader, newUuidV4);
    handler.next(options);
  }
}
