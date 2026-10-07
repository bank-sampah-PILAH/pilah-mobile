import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class _MockSecureDatabase extends Mock implements SecureDatabase {}

Response<dynamic> _response(int? status, [Object? data]) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: status,
      data: data,
    );

DioException _dio(DioExceptionType type, {Response<dynamic>? response}) =>
    DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: response,
    );

void main() {
  group('NetworkException.handleBadResponse', () {
    final expected = <int, Matcher>{
      400: isA<BadRequestException>(),
      401: isA<UnauthorisedException>(),
      403: isA<BadRequestException>(),
      404: isA<NotFoundException>(),
      409: isA<ConflictException>(),
      408: isA<SendTimeOutException>(),
      413: isA<RequestEntityTooLargeException>(),
      422: isA<UnprocessableEntityException>(),
      500: isA<InternalServerErrorException>(),
      503: isA<InternalServerErrorException>(),
    };

    expected.forEach((status, matcher) {
      test('$status maps to its exception type', () {
        expect(NetworkException.handleBadResponse(_response(status)), matcher);
      });
    });

    test('anything else is a communication error naming the code', () {
      final error = NetworkException.handleBadResponse(_response(418));

      expect(error, isA<FetchDataException>());
      expect(error.message, 'Received invalid status code: 418');
    });

    test('a missing response counts as status 0', () {
      final error = NetworkException.handleBadResponse(null);

      expect(error.message, 'Received invalid status code: 0');
    });

    test('carries the backend message through', () {
      final error =
          NetworkException.handleBadResponse(_response(400, {'error': 'Salah'}))
              as BadRequestException;

      expect(error.displayMessage, 'Salah');
      expect(error.getErrorMessage(), 'Salah');
      expect(
          (NetworkException.handleBadResponse(_response(422, {'error': 'X'}))
                  as UnprocessableEntityException)
              .getErrorMessage(),
          'X');
    });
  });

  group('NetworkException.handleException', () {
    test('maps every Dio failure type', () {
      expect(
          NetworkException.handleException(
              _dio(DioExceptionType.badResponse, response: _response(404))),
          isA<NotFoundException>());
      expect(
          NetworkException.handleException(
              _dio(DioExceptionType.connectionTimeout)),
          isA<ConnectionTimeOutException>());
      expect(
          NetworkException.handleException(_dio(DioExceptionType.sendTimeout)),
          isA<SendTimeOutException>());
      expect(
          NetworkException.handleException(
              _dio(DioExceptionType.receiveTimeout)),
          isA<ReceiveTimeOutException>());
      expect(NetworkException.handleException(_dio(DioExceptionType.cancel)),
          isA<RequestCancelled>());
      expect(
          NetworkException.handleException(
              _dio(DioExceptionType.badCertificate)),
          isA<BadCertificate>());
      expect(
          NetworkException.handleException(
              _dio(DioExceptionType.connectionError)),
          isA<FetchDataException>());
      expect(NetworkException.handleException(_dio(DioExceptionType.unknown)),
          isA<FetchDataException>());
    });

    test('other exceptions become a general exception', () {
      expect(NetworkException.handleException(const FormatException('x')),
          isA<GeneralException>());
      expect(NetworkException.handleException(const SocketException('offline')),
          isA<GeneralException>());
      expect(NetworkException.handleException(Exception('boom')).message,
          contains('boom'));
    });
  });

  group('message extraction', () {
    test('reads the first validation error, list or scalar', () {
      expect(
          NetworkException.extractMessage(_response(422, {
            'errors': {
              'a': ['pertama', 'kedua']
            },
          })),
          'pertama');
      expect(
          NetworkException.extractMessage(_response(422, {
            'errors': {'a': 'tunggal'},
          })),
          'tunggal');
      expect(
          NetworkException.extractMessage(_response(422, {
            'errors': {'a': <String>[]},
          })),
          '[]');
    });

    test('falls back to error, message or detail', () {
      expect(
          NetworkException.extractMessage(_response(400, {'error': 'e'})), 'e');
      expect(NetworkException.extractMessage(_response(400, {'message': 'm'})),
          'm');
      expect(NetworkException.extractMessage(_response(400, {'detail': 'd'})),
          'd');
      expect(
          NetworkException.extractMessage(
              _response(400, {'errors': <String, dynamic>{}, 'error': 'e'})),
          'e');
    });

    test('accepts a plain string body and ignores nothing useful', () {
      expect(NetworkException.extractMessage(_response(500, 'gagal')), 'gagal');
      expect(NetworkException.extractMessage(_response(500, '')), isNull);
      expect(NetworkException.extractMessage(_response(500, {'x': 1})), isNull);
      expect(NetworkException.extractMessage(null), isNull);
    });

    test('flattens validation errors per field', () {
      final error = NetworkException(
        response: _response(422, {
          'errors': {
            'kode': ['Kode dipakai'],
            'no_hp': 'Nomor salah',
            'kosong': <String>[],
            'nol': null,
          },
        }),
      );

      expect(error.fieldErrors(), {
        'kode': 'Kode dipakai',
        'no_hp': 'Nomor salah',
        'kosong': '[]',
      });
      expect(error.fieldError(['phone', 'no_hp']), 'Nomor salah');
      expect(error.fieldError(['absent']), isNull);
    });

    test('no field errors without an errors map', () {
      expect(NetworkException().fieldErrors(), isEmpty);
      expect(
          NetworkException(response: _response(400, {'error': 'x'}))
              .fieldErrors(),
          isEmpty);
      expect(
          NetworkException(response: _response(400, {'errors': 'x'}))
              .fieldErrors(),
          isEmpty);
    });

    test('displayMessage prefers message, then the body, then the prefix', () {
      expect(NetworkException(message: 'a', prefix: 'p').displayMessage, 'a');
      expect(
          NetworkException(
              prefix: 'p',
              response: _response(400, {'error': 'b'})).displayMessage,
          'b');
      expect(NetworkException(prefix: 'p').displayMessage, 'p');
      expect(NetworkException().displayMessage, 'Terjadi kesalahan');
    });

    test('the remaining exception types carry their prefixes', () {
      expect(InvalidInputException().prefix, 'Invalid Input');
      expect(RequestCancelled().prefix, 'Request Cancelled');
      expect(BadCertificate().prefix, 'BadCertificate');
      expect(GeneralException(message: 'x').prefix, 'General Exception');
    });
  });

  group('apiCall', () {
    Future<NetworkException> failure(Future<dynamic> func) async {
      final result = await apiCall<int>(func: func, mapper: (v) => v as int);
      return result.fold((l) => l, (r) => fail('expected a failure'));
    }

    test('maps a success', () async {
      final result = await apiCall<int>(
          func: Future.value(2), mapper: (v) => (v as int) * 2);

      expect(result.fold((l) => null, (r) => r), 4);
    });

    test('maps every Dio failure type', () async {
      expect(
          await failure(Future.error(
              _dio(DioExceptionType.badResponse, response: _response(401)))),
          isA<UnauthorisedException>());
      expect(
          await failure(Future.error(_dio(DioExceptionType.connectionTimeout))),
          isA<ConnectionTimeOutException>());
      expect(await failure(Future.error(_dio(DioExceptionType.sendTimeout))),
          isA<SendTimeOutException>());
      expect(await failure(Future.error(_dio(DioExceptionType.receiveTimeout))),
          isA<ReceiveTimeOutException>());
      expect(await failure(Future.error(_dio(DioExceptionType.cancel))),
          isA<RequestCancelled>());
      expect(await failure(Future.error(_dio(DioExceptionType.badCertificate))),
          isA<BadCertificate>());
      expect(await failure(Future.error(_dio(DioExceptionType.unknown))),
          isA<FetchDataException>());
    });

    test('anything else is a general exception, including mapper crashes',
        () async {
      expect(await failure(Future.error(const FormatException('x'))),
          isA<GeneralException>());
      expect(await failure(Future.error(const SocketException('x'))),
          isA<GeneralException>());
      expect(
          await failure(Future.value('not an int')), isA<GeneralException>());
    });
  });

  group('NetworkUtils', () {
    late _MockSecureDatabase db;
    late NetworkUtils utils;

    setUp(() {
      db = _MockSecureDatabase();
      utils = NetworkUtils(db);
    });

    test('init restores the saved tokens', () async {
      when(() => db.getString(AppKey.token)).thenAnswer((_) async => 'a');
      when(() => db.getString(AppKey.refreshToken))
          .thenAnswer((_) async => 'r');

      await utils.init();

      expect(utils.accessToken, 'a');
      expect(utils.refreshToken, 'r');
    });

    test('init without saved tokens leaves them blank', () async {
      when(() => db.getString(any())).thenAnswer((_) async => null);

      await utils.init();

      expect(utils.accessToken, '');
      expect(utils.refreshToken, '');
    });

    test('set and delete keep the session in memory', () async {
      await utils.setToken(accessToken: 'a', refreshToken: 'r');
      expect(utils.accessToken, 'a');

      await utils.deleteToken();
      expect(utils.accessToken, '');
      expect(utils.refreshToken, '');
    });

    test('parseErrorMessage reads message, first value or the raw value', () {
      expect(NetworkUtils.parseErrorMessage({'message': 'm', 'x': 'y'}), 'm');
      expect(NetworkUtils.parseErrorMessage({'x': 'y'}), 'y');
      expect(NetworkUtils.parseErrorMessage('plain'), 'plain');
      expect(NetworkUtils.parseErrorMessage(3), '3');
    });
  });
}
