import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/errors/error_type_name.dart';

class _OurOwnProblem implements Exception {}

void main() {
  group('ErrorTypeName.of', () {
    test('names the common Dart errors', () {
      expect(ErrorTypeName.of(StateError('x')), 'StateError');
      expect(ErrorTypeName.of(const FormatException('x')), 'FormatException');
      expect(ErrorTypeName.of(ArgumentError('x')), 'ArgumentError');
      expect(ErrorTypeName.of(RangeError('x')), 'RangeError');
      expect(ErrorTypeName.of(UnsupportedError('x')), 'UnsupportedError');
      expect(ErrorTypeName.of(AssertionError('x')), 'AssertionError');
      expect(ErrorTypeName.of(FlutterError('x')), 'FlutterError');
    });

    test('names a network failure after its kind', () {
      expect(ErrorTypeName.of(InternalServerErrorException()),
          'InternalServerErrorException');
      expect(ErrorTypeName.of(FetchDataException()), 'FetchDataException');
      expect(
        ErrorTypeName.of(DioException(requestOptions: RequestOptions())),
        'DioException',
      );
    });

    test('falls back to the real name outside the web, which keeps it', () {
      expect(ErrorTypeName.of(_OurOwnProblem()), '_OurOwnProblem');
    });
  });
}
