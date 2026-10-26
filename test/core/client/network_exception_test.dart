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
}
