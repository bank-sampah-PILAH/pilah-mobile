import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

/// What an error says about the HTTP call that failed, so the team can tell
/// which endpoint answered with what, without opening the server's log.
abstract final class ErrorHttp {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _number = RegExp(r'^\d+$');

  /// The status the server answered with, or null if there was no answer.
  static int? statusOf(Object error) => _response(error)?.statusCode;

  /// The endpoint that was called, without the query and with every id
  /// replaced by `:id`, so `/nasabah/3f2b…/` and `/nasabah/9a1c…/` are one
  /// endpoint and a name in the query never leaves the app. Null if the error
  /// came from no request.
  static String? pathOf(Object error) {
    final options = _options(error);
    if (options == null) return null;
    final path = options.uri.path;
    return path
        .split('/')
        .map((part) =>
            _uuid.hasMatch(part) || _number.hasMatch(part) ? ':id' : part)
        .join('/');
  }

  static Response<dynamic>? _response(Object error) => switch (error) {
        NetworkException(:final response) => response,
        DioException(:final response) => response,
        _ => null,
      };

  static RequestOptions? _options(Object error) => switch (error) {
        NetworkException(:final response) => response?.requestOptions,
        DioException(:final requestOptions) => requestOptions,
        _ => null,
      };
}
