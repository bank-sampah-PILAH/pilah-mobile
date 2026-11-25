import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

/// Decides which errors are worth telling the team about.
///
/// A required field left empty, a 404 the screen explains, or a phone with no
/// signal are not faults in the app: reporting them would bury the real ones.
/// A server failure and anything nobody expected are reported.
abstract final class ErrorFilter {
  static bool shouldReport(Object error) {
    if (error is InternalServerErrorException) return true;
    if (error is NetworkException) return _isServerFailure(error.response);
    if (error is DioException) {
      return error.type == DioExceptionType.badResponse &&
          _isServerFailure(error.response);
    }
    return true;
  }

  static bool _isServerFailure(Response<dynamic>? response) =>
      (response?.statusCode ?? 0) >= 500;
}
