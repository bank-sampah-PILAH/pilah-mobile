import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/request_id_interceptor.dart';

/// The id of the request an error came from, so the server's log can be
/// searched for it. Null for an error that has no request.
abstract final class ErrorRequestId {
  static String? of(Object error) {
    final options = switch (error) {
      NetworkException(:final response) => response?.requestOptions,
      DioException(:final requestOptions) => requestOptions,
      _ => null,
    };
    final id = options?.headers[requestIdHeader];
    return id is String && id.isNotEmpty ? id : null;
  }
}
