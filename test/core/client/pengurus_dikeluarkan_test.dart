import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/pengurus_dikeluarkan.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, String body) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'));
  dio.httpClientAdapter = _Adapter(status, body);
  dio.interceptors.add(PengurusDikeluarkanInterceptor());
  return dio;
}

void main() {
  late List<String> raised;
  late StreamSubscription<String> subscription;

  setUp(() {
    raised = [];
    subscription = PengurusDikeluarkanSignal.stream.listen(raised.add);
  });

  tearDown(() => subscription.cancel());

  test('a 403 with the code raises the signal with the server message',
      () async {
    final dio = _dio(403,
        '{"error":"Anda sudah dikeluarkan dari bank sampah ini","code":"pengurus_dikeluarkan"}');

    await expectLater(dio.get('/api/v1/team'), throwsA(isA<DioException>()));

    expect(raised, ['Anda sudah dikeluarkan dari bank sampah ini']);
  });

  test('the same code without a message falls back to a clear one', () async {
    final dio = _dio(403, '{"code":"pengurus_dikeluarkan"}');

    await expectLater(dio.get('/x'), throwsA(isA<DioException>()));

    expect(raised, [pengurusDikeluarkanFallbackMessage]);
  });

  test('the error still reaches the caller untouched', () async {
    final dio = _dio(403, '{"error":"x","code":"pengurus_dikeluarkan"}');

    try {
      await dio.get('/x');
      fail('expected a DioException');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 403);
      expect(e.response?.data['code'], 'pengurus_dikeluarkan');
    }
  });

  for (final (name, status, body) in [
    ('another 403', 403, '{"error":"Tidak diizinkan"}'),
    ('another code', 403, '{"error":"x","code":"lain"}'),
    ('the code on another status', 404, '{"code":"pengurus_dikeluarkan"}'),
    ('a body that is not an object', 403, '["pengurus_dikeluarkan"]'),
  ]) {
    test('$name raises nothing', () async {
      final dio = _dio(status, body);

      await expectLater(dio.get('/x'), throwsA(isA<DioException>()));

      expect(raised, isEmpty);
    });
  }

  test('a failure without a response raises nothing', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _ThrowingAdapter()
      ..interceptors.add(PengurusDikeluarkanInterceptor());

    await expectLater(dio.get('/x'), throwsA(isA<DioException>()));

    expect(raised, isEmpty);
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      throw StateError('offline');

  @override
  void close({bool force = false}) {}
}
