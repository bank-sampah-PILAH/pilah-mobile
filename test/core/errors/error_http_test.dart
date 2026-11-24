import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/request_id_interceptor.dart';
import 'package:pilah_mobile/core/client/server_error_interceptor.dart';
import 'package:pilah_mobile/core/errors/error_http.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

import '../../support/stub_api.dart';

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];
  final contexts = <Map<String, Object?>>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    errors.add(error);
    contexts.add(context);
  }
}

class _ThrowingReporter implements ErrorReporter {
  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) =>
      throw StateError('the monitoring service is down');
}

Response<dynamic> _response(String path, int status, {String? id}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(
        path: path,
        baseUrl: 'http://api.test',
        headers: {if (id != null) requestIdHeader: id},
      ),
      statusCode: status,
    );

void main() {
  group('ErrorHttp', () {
    test('finds the status of the failed answer', () {
      expect(
        ErrorHttp.statusOf(
            InternalServerErrorException(response: _response('/x', 503))),
        503,
      );
      expect(
        ErrorHttp.statusOf(DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: _response('/x', 500),
        )),
        500,
      );
      expect(ErrorHttp.statusOf(StateError('x')), isNull);
      expect(ErrorHttp.statusOf(InternalServerErrorException()), isNull);
    });

    test('names the endpoint without its query or the ids in it', () {
      const uuid = '3f2b8c1e-5a4d-4e6f-9a1b-0c2d3e4f5a6b';
      expect(
        ErrorHttp.pathOf(InternalServerErrorException(
          response: _response('/api/v1/nasabah/$uuid/?q=budi&page=2', 500),
        )),
        '/api/v1/nasabah/:id/',
      );
      expect(
        ErrorHttp.pathOf(InternalServerErrorException(
          response: _response('/api/v1/transaksi/42', 500),
        )),
        '/api/v1/transaksi/:id',
      );
      expect(
        ErrorHttp.pathOf(InternalServerErrorException(
          response: _response('/api/v1/dashboard/stats', 500),
        )),
        '/api/v1/dashboard/stats',
      );
      expect(ErrorHttp.pathOf(StateError('x')), isNull);
    });

    test('gathers the id, status and endpoint of a failed call', () {
      expect(
        ErrorHttp.contextOf(InternalServerErrorException(
            response: _response('/api/v1/jadwal?page=1', 503, id: 'r-9'))),
        {
          'id_permintaan': 'r-9',
          'http_status': 503,
          'jalur_api': '/api/v1/jadwal',
        },
      );
      expect(ErrorHttp.contextOf(StateError('x')), isEmpty);
    });

    test('carries nothing from the body of the response', () {
      const personal = 'Saldo Budi Santoso Rp 50.000 di Jl. Melati 5';
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/api/v1/setoran/42',
          baseUrl: 'http://api.test',
          headers: {requestIdHeader: 'r-1'},
        ),
        statusCode: 500,
        data: {'error': personal, 'detail': personal},
      );

      final context = ErrorHttp.contextOf(
        InternalServerErrorException(response: response),
      );

      expect(context, {
        'id_permintaan': 'r-1',
        'http_status': 500,
        'jalur_api': '/api/v1/setoran/:id',
      });
      expect(context.toString(), isNot(contains('Budi')));
    });

    test('writes a base url that ends in a slash as one slash', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/api/v1/jadwal',
          baseUrl: 'http://api.test/',
        ),
        statusCode: 500,
      );

      expect(ErrorHttp.pathOf(InternalServerErrorException(response: response)),
          '/api/v1/jadwal');
    });
  });

  group('ContextualErrorReporter', () {
    ContextualErrorReporter build(ErrorReporter inner, {String version = ''}) =>
        ContextualErrorReporter(
          inner: inner,
          currentScreen: () => null,
          appVersion: version,
        );

    test('adds the status and the endpoint of a failed request', () {
      final inner = _RecordingReporter();

      build(inner).report(
        InternalServerErrorException(
            response: _response('/api/v1/jadwal?page=1', 500, id: 'r-1')),
        StackTrace.current,
      );

      expect(inner.contexts.single, {
        'http_status': 500,
        'jalur_api': '/api/v1/jadwal',
        'id_permintaan': 'r-1',
      });
      expect(AnalyticsProps.sanitize(inner.contexts.single)['jalur_api'],
          '/api/v1/jadwal');
    });

    test('adds the app version when the build has one, and omits it if not',
        () {
      final inner = _RecordingReporter();

      build(inner, version: '2.1.0+10')
          .report(StateError('x'), StackTrace.current);
      build(inner).report(StateError('x'), StackTrace.current);

      expect(inner.contexts[0], {'versi_app': '2.1.0+10'});
      expect(inner.contexts[1], isEmpty);
    });
  });

  group('DeduplicatingErrorReporter', () {
    test('reports a failed request once, however many places catch it', () {
      final inner = _RecordingReporter();
      final reporter = DeduplicatingErrorReporter(inner: inner);
      final response = _response('/x', 500, id: 'r-1');

      reporter.report(DioException(requestOptions: response.requestOptions),
          StackTrace.current);
      reporter.report(
          InternalServerErrorException(response: response), StackTrace.current);
      reporter.report(
          InternalServerErrorException(
              response: _response('/x', 500, id: 'r-2')),
          StackTrace.current);

      expect(inner.errors, hasLength(2));
    });

    test('never drops an error that has no request id', () {
      final inner = _RecordingReporter();
      final reporter = DeduplicatingErrorReporter(inner: inner);

      reporter.report(StateError('x'), StackTrace.current);
      reporter.report(StateError('x'), StackTrace.current);

      expect(inner.errors, hasLength(2));
    });

    test('forgets old requests so memory stays bounded', () {
      final inner = _RecordingReporter();
      final reporter = DeduplicatingErrorReporter(inner: inner, remember: 2);
      DioException failed(String id) => DioException(
          requestOptions: _response('/x', 500, id: id).requestOptions);

      reporter.report(failed('a'), StackTrace.current);
      reporter.report(failed('b'), StackTrace.current);
      reporter.report(failed('c'), StackTrace.current);
      reporter.report(failed('a'), StackTrace.current);

      expect(inner.errors, hasLength(4));
    });
  });

  group('ServerErrorInterceptor', () {
    late StubApi api;
    late _RecordingReporter reporter;

    setUp(() {
      api = StubApi();
      reporter = _RecordingReporter();
      api.network.dio.interceptors.add(ServerErrorInterceptor(reporter));
      api.on('GET', '/boom', status: 500, json: {'detail': 'x'});
      api.on('GET', '/missing', status: 404, json: {'detail': 'x'});
      api.on('GET', '/ok', json: {});
    });

    test('reports a server failure even though the screen will handle it',
        () async {
      await expectLater(api.network.get('/boom'), throwsA(isA<DioException>()));

      expect(reporter.errors.single, isA<DioException>());
      expect(ErrorHttp.statusOf(reporter.errors.single), 500);
    });

    test('leaves answers that are not server failures alone', () async {
      await api.network.get('/ok');
      await expectLater(
          api.network.get('/missing'), throwsA(isA<DioException>()));

      expect(reporter.errors, isEmpty);
    });

    test('still lets the error reach the caller', () async {
      await expectLater(
          api.network.get('/boom'),
          throwsA(isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 500)));
    });

    test('a reporter that fails does not disturb the call', () async {
      api.network.dio.interceptors
          .add(ServerErrorInterceptor(SafeErrorReporter(_ThrowingReporter())));

      await expectLater(api.network.get('/boom'), throwsA(isA<DioException>()));
    });
  });
}
