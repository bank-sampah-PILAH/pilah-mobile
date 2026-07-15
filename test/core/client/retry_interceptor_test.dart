import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/retry_interceptor.dart';

/// Fails the first [dropCount] requests by throwing [dropError], then answers
/// normally.
///
/// Throwing from the adapter reproduces the real classification path: Dio wraps
/// any non-Dio error via `assureDioException`, which yields
/// [DioExceptionType.unknown] with a null response — exactly what a connection
/// dying after the socket opened looks like in production.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter({
    this.dropCount = 0,
    this.statusCode = 200,
    Object Function(RequestOptions options)? dropError,
  }) : _dropError = dropError ??
            ((_) => const SocketException('Connection reset by peer'));

  final int dropCount;
  final int statusCode;
  final Object Function(RequestOptions options) _dropError;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls <= dropCount) {
      throw _dropError(options);
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_FlakyAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(dio));
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test('a GET dropped once succeeds on the retry', () async {
      final adapter = _FlakyAdapter(dropCount: 1);
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/api/v1/transaksi');

      expect(response.statusCode, 200);
      expect(adapter.calls, 2, reason: 'one original attempt plus one retry');
    });

    test('retries exactly once — a GET dropped twice still fails', () async {
      final adapter = _FlakyAdapter(dropCount: 2);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<dynamic>('/api/v1/transaksi'),
        throwsA(isA<DioException>()),
      );
      expect(
        adapter.calls,
        2,
        reason: 'must not retry endlessly — one retry then give up',
      );
    });

    test('a dropped POST is NOT retried — it may have already been written',
        () async {
      final adapter = _FlakyAdapter(dropCount: 1);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.post<dynamic>('/api/v1/transaksi', data: const {'nasabah_id': '1'}),
        throwsA(isA<DioException>()),
      );
      expect(
        adapter.calls,
        1,
        reason: 'replaying a write risks duplicating a transaksi',
      );
    });

    test('a server error response is not retried — the server did answer',
        () async {
      final adapter = _FlakyAdapter(statusCode: 500);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<dynamic>('/api/v1/transaksi'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1, reason: 'a 500 is a real error, not a drop');
    });

    test('a healthy GET is passed straight through', () async {
      final adapter = _FlakyAdapter();
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/api/v1/transaksi');

      expect(response.statusCode, 200);
      expect(adapter.calls, 1);
    });

    // The regression this class exists for. A keep-alive socket reused as the
    // server closes it raises HttpException, not SocketException — the previous
    // gate matched on the exception class and so never fired for the real bug.
    test('a GET killed by HttpException mid-flight is retried', () async {
      final adapter = _FlakyAdapter(
        dropCount: 1,
        dropError: (_) => const HttpException(
          'Connection closed before full header was received',
        ),
      );
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/api/v1/transaksi');

      expect(response.statusCode, 200);
      expect(
        adapter.calls,
        2,
        reason: 'retrying must not depend on which exception class was thrown',
      );
    });

    test('a GET killed by an unforeseen exception type is still retried',
        () async {
      final adapter = _FlakyAdapter(
        dropCount: 1,
        dropError: (_) => const FormatException('something nobody predicted'),
      );
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/api/v1/transaksi');

      expect(response.statusCode, 200);
      expect(adapter.calls, 2, reason: 'the shape gate must be future-proof');
    });

    test('a cancelled request is not retried — it was deliberate', () async {
      final adapter = _FlakyAdapter(
        dropCount: 1,
        dropError: (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      );
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<dynamic>('/api/v1/transaksi'),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.cancel)),
      );
      expect(adapter.calls, 1);
    });

    test('a timeout is not retried — it already spent its full budget',
        () async {
      final adapter = _FlakyAdapter(
        dropCount: 1,
        dropError: (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<dynamic>('/api/v1/transaksi'),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.receiveTimeout)),
      );
      expect(
        adapter.calls,
        1,
        reason: 'retrying a timeout would double a stall the user is watching',
      );
    });

    test('a dropped POST is still not retried, whatever the exception type',
        () async {
      final adapter = _FlakyAdapter(
        dropCount: 1,
        dropError: (_) => const HttpException('Connection closed'),
      );
      final dio = _dioWith(adapter);

      await expectLater(
        dio.post<dynamic>('/api/v1/transaksi', data: const {'nasabah_id': '1'}),
        throwsA(isA<DioException>()),
      );
      expect(
        adapter.calls,
        1,
        reason: 'widening the gate must not start replaying writes',
      );
    });
  });
}
