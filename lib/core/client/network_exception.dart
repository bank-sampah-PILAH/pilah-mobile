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
    var message = response?.data['message'];
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

  String? getErrorMessage() {
    return response?.data != null && response?.data['message'] != null
        ? response!.data['message']
        : null;
  }
}

class BadRequestException extends NetworkException {
  BadRequestException({super.message, super.response})
      : super(
          prefix: 'Invalid Request',
        );

  String? getErrorMessage() {
    return response?.data != null && response?.data['message'] != null
        ? response!.data['message']
        : null;
  }
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
