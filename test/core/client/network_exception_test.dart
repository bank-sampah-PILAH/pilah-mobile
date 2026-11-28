import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

void main() {
  group('NetworkException.extractMessage', () {
    test('decodes JSON errors returned as response bytes', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/export'),
        data: utf8.encode('{"error":"Tidak ada data"}'),
      );

      expect(NetworkException.extractMessage(response), 'Tidak ada data');
    });

    test('returns no message for non-object JSON bytes', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/export'),
        data: utf8.encode('["not an error object"]'),
      );

      expect(NetworkException.extractMessage(response), isNull);
    });
  });

  group('NetworkException.handleBadResponse', () {
    test('keeps the response of a server failure, so its request can be found',
        () {
      for (final status in [500, 503]) {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
        );

        final error = NetworkException.handleBadResponse(response);

        expect(error, isA<InternalServerErrorException>(), reason: '$status');
        expect(error.response, same(response), reason: '$status');
      }
    });
  });
}
