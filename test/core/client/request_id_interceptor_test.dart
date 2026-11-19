import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/request_id_interceptor.dart';

/// Answers every request with 200 and remembers what it was asked.
class _CapturingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = _CapturingAdapter();
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(RequestIdInterceptor());
  });

  group('RequestIdInterceptor', () {
    test('gives every request its own id in X-Request-Id', () async {
      await dio.get<dynamic>('https://api.test/a');
      await dio.get<dynamic>('https://api.test/b');

      final ids = [
        for (final r in adapter.requests) r.headers[requestIdHeader] as String,
      ];
      expect(ids, hasLength(2));
      expect(ids[0], isNot(ids[1]));
      expect(
        ids[0],
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );
    });

    test('keeps an id that is already there, so a retry is the same request',
        () async {
      await dio.get<dynamic>(
        'https://api.test/a',
        options: Options(headers: {requestIdHeader: 'abc-123'}),
      );

      expect(adapter.requests.single.headers[requestIdHeader], 'abc-123');
    });
  });
}
