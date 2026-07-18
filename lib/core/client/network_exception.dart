import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class NetworkException implements Exception {
  final String? message;
  final String? prefix;
  final Response? response;

  NetworkException({
    this.message,
    this.prefix,
    this.response,
  });

  static NetworkException handleBadResponse(Response? response) {
    var statusCode = response?.statusCode ?? 0;
    var message = extractMessage(response);
    switch (statusCode) {
      case 400:
        return BadRequestException(response: response, message: message);
      case 401:
        return UnauthorisedException(response: response, message: message);
      case 403:
        return BadRequestException(response: response, message: message);
      case 404:
        return NotFoundException(response: response, message: message);
      case 409:
        return ConflictException(response: response, message: message);
      case 408:
        return SendTimeOutException();
      case 413:
        return RequestEntityTooLargeException(
            response: response, message: message);
      case 422:
        return UnprocessableEntityException(
            response: response, message: message);
      case 500:
        return InternalServerErrorException();
      case 503:
        return InternalServerErrorException();
      default:
        var responseCode = statusCode;
        return FetchDataException(
          message: 'Received invalid status code: $responseCode',
          response: response,
        );
    }
  }

  static NetworkException handleException(Exception e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.badResponse:
          final err = NetworkException.handleBadResponse(e.response);
          Logger().e(err.toString());
          return err;
        case DioExceptionType.connectionTimeout:
          return ConnectionTimeOutException();
        case DioExceptionType.sendTimeout:
          return SendTimeOutException();
        case DioExceptionType.receiveTimeout:
          return ReceiveTimeOutException();
        case DioExceptionType.cancel:
          return RequestCancelled();
        case DioExceptionType.badCertificate:
          return BadCertificate();
        default:
          return FetchDataException();
      }
    }
    if (e is FormatException) {
      Logger().e('Error: Format from front end error');
    } else if (e is SocketException) {
      Logger().e('Error: No Internet Connection');
    }
    return GeneralException(message: e.toString());
  }

  /// Extracts a human-readable message from the PILAH backend error payload.
  ///
  /// The Django API returns either:
  ///  - validation / duplicate errors (HTTP 422): `{"errors": {"field": ["msg"]}}`
  ///  - other errors (401/403/404/400): `{"error": "msg"}`
  static String? extractMessage(Response? response) {
    final data = response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
      final singleError = data['error'] ?? data['message'] ?? data['detail'];
      if (singleError != null) return singleError.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  /// Flattens `{"errors": {"field": ["msg"]}}` into `{field: "msg"}` so forms can
  /// surface backend validation (e.g. duplicate `kode`) against the right field.
  Map<String, String> fieldErrors() {
    final data = response?.data;
    final result = <String, String>{};
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            result[key.toString()] = value.first.toString();
          } else if (value != null) {
            result[key.toString()] = value.toString();
          }
        });
      }
    }
    return result;
  }

  /// Looks up the first of [keys] present in [fieldErrors], or `null` if the
  /// backend reported no error against any of them.
  ///
  /// Lets a form ask "did this failure belong to my phone field?" without
  /// caring which alias the API used for it.
  String? fieldError(List<String> keys) {
    final fields = fieldErrors();
    for (final key in keys) {
      final message = fields[key];
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }

  /// The best user-facing message for this exception, falling back to the prefix.
  String get displayMessage =>
      message ?? extractMessage(response) ?? prefix ?? 'Terjadi kesalahan';
}

class ConnectionTimeOutException extends NetworkException {
  ConnectionTimeOutException() : super(prefix: 'Connection Timeout');
}

class ReceiveTimeOutException extends NetworkException {
  ReceiveTimeOutException() : super(prefix: 'Receive Timeout');
}

class SendTimeOutException extends NetworkException {
  SendTimeOutException() : super(prefix: 'Send Timeout');
}

class InternalServerErrorException extends NetworkException {
  InternalServerErrorException() : super(prefix: 'Internal Server Error');
}

class ConflictException extends NetworkException {
  ConflictException({super.message, super.response})
      : super(
          prefix: 'Conflict',
        );
}

class RequestEntityTooLargeException extends NetworkException {
  RequestEntityTooLargeException({super.message, super.response})
      : super(
          prefix: 'Request Entity Too Large',
        );
}

class FetchDataException extends NetworkException {
  FetchDataException({super.message, super.response})
      : super(
          prefix: 'Error During Communication',
        );
}

class NotFoundException extends NetworkException {
  NotFoundException({super.message, super.response})
      : super(
          prefix: 'Not Found',
        );
}

class UnprocessableEntityException extends NetworkException {
  UnprocessableEntityException({super.message, super.response})
      : super(
          prefix: 'Invalid Request',
        );

  String? getErrorMessage() => NetworkException.extractMessage(response);
}

class BadRequestException extends NetworkException {
  BadRequestException({super.message, super.response})
      : super(
          prefix: 'Invalid Request',
        );

  String? getErrorMessage() => NetworkException.extractMessage(response);
}

class UnauthorisedException extends NetworkException {
  UnauthorisedException({super.message, super.response})
      : super(prefix: 'Unauthorised');
}

class InvalidInputException extends NetworkException {
  InvalidInputException({super.message, super.response})
      : super(prefix: 'Invalid Input');
}

class RequestCancelled extends NetworkException {
  RequestCancelled({super.message, super.response})
      : super(prefix: 'Request Cancelled');
}

class BadCertificate extends NetworkException {
  BadCertificate({super.message, super.response})
      : super(prefix: 'BadCertificate');
}

class GeneralException extends NetworkException {
  GeneralException({super.message}) : super(prefix: 'General Exception');
}
