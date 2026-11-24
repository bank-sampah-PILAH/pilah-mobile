import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/errors/error_filter.dart';

Response<dynamic> _response(int status) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: status,
    );

DioException _dio(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null ? null : _response(status),
    );

void main() {
  group('ErrorFilter.shouldReport', () {
    test('does not report what a screen already answers to the user', () {
      final answered = <Object>[
        BadRequestException(response: _response(400)),
        UnauthorisedException(response: _response(401)),
        NotFoundException(response: _response(404)),
        ConflictException(response: _response(409)),
        RequestEntityTooLargeException(response: _response(413)),
        UnprocessableEntityException(response: _response(422)),
        InvalidInputException(),
      ];
      for (final error in answered) {
        expect(ErrorFilter.shouldReport(error), isFalse, reason: '$error');
      }
    });

    test('reports a server failure', () {
      final failures = <Object>[
        InternalServerErrorException(),
        FetchDataException(response: _response(502)),
        _dio(DioExceptionType.badResponse, status: 503),
      ];
      for (final error in failures) {
        expect(ErrorFilter.shouldReport(error), isTrue, reason: '$error');
      }
    });

    test('does not report the user having no connection', () {
      final connection = <Object>[
        ConnectionTimeOutException(),
        ReceiveTimeOutException(),
        SendTimeOutException(),
        RequestCancelled(),
        BadCertificate(),
        _dio(DioExceptionType.connectionError),
        _dio(DioExceptionType.badResponse, status: 422),
      ];
      for (final error in connection) {
        expect(ErrorFilter.shouldReport(error), isFalse, reason: '$error');
      }
    });

    test('reports anything nobody expected', () {
      final unexpected = <Object>[
        StateError('no element'),
        const FormatException('bad number'),
        ArgumentError('x'),
        Exception('plain'),
      ];
      for (final error in unexpected) {
        expect(ErrorFilter.shouldReport(error), isTrue, reason: '$error');
      }
    });
  });
}
