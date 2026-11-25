import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

/// The name an error is filed under, such as `StateError`.
///
/// `error.runtimeType.toString()` is not good enough: a release build of the
/// web app shortens class names (`minified:fI`), differently in every build, so
/// the same fault would be filed under a new name with each release. The types
/// listed here are recognised by what they are, which no compiler changes.
abstract final class ErrorTypeName {
  static String of(Object error) {
    // The most specific first: `InternalServerErrorException` is also a
    // `NetworkException`.
    return switch (error) {
      InternalServerErrorException() => 'InternalServerErrorException',
      FetchDataException() => 'FetchDataException',
      ConnectionTimeOutException() => 'ConnectionTimeOutException',
      ReceiveTimeOutException() => 'ReceiveTimeOutException',
      SendTimeOutException() => 'SendTimeOutException',
      UnprocessableEntityException() => 'UnprocessableEntityException',
      BadRequestException() => 'BadRequestException',
      UnauthorisedException() => 'UnauthorisedException',
      NotFoundException() => 'NotFoundException',
      ConflictException() => 'ConflictException',
      RequestEntityTooLargeException() => 'RequestEntityTooLargeException',
      InvalidInputException() => 'InvalidInputException',
      RequestCancelled() => 'RequestCancelled',
      BadCertificate() => 'BadCertificate',
      GeneralException() => 'GeneralException',
      NetworkException() => 'NetworkException',
      DioException() => 'DioException',
      FlutterError() => 'FlutterError',
      StateError() => 'StateError',
      FormatException() => 'FormatException',
      RangeError() => 'RangeError',
      ArgumentError() => 'ArgumentError',
      // Before `UnsupportedError`, which it implements.
      UnimplementedError() => 'UnimplementedError',
      UnsupportedError() => 'UnsupportedError',
      AssertionError() => 'AssertionError',
      TypeError() => 'TypeError',
      _ => kIsWeb ? 'Error' : error.runtimeType.toString(),
    };
  }
}
