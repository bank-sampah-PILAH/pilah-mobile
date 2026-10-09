import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

import '../../support/stub_api.dart';

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('GET', '/ping', json: {'ok': true});
    api.on('POST', '/ping', json: {'ok': true});
    api.on('PUT', '/ping', json: {'ok': true});
    api.on('PATCH', '/ping', json: {'ok': true});
    api.on('DELETE', '/ping', json: {'ok': true});
  });

  test('GET targets the base URL with query and the bearer token', () async {
    final response = await api.network.get('/ping', queryParams: {'a': '1'});

    expect(response.data, {'ok': true});
    expect(api.last.method, 'GET');
    expect(api.last.query, {'a': '1'});
    expect(api.last.headers['Authorization'], 'Bearer token-123');
    expect(api.last.headers['Accept'], 'application/json');
  });

  test('omits the Authorization header when signed out', () async {
    final anon = StubApi(accessToken: '');
    anon.on('GET', '/ping', json: {});

    await anon.network.get('/ping');

    expect(anon.last.headers.containsKey('Authorization'), isFalse);
  });

  test('POST sends the JSON-encoded body', () async {
    await api.network.post('/ping', data: {'x': 1}, queryParams: {'q': 'z'});

    expect(api.last.method, 'POST');
    expect(jsonDecode(api.last.body as String), {'x': 1});
    expect(api.last.query, {'q': 'z'});
  });

  test('POST prefers form data over the JSON body', () async {
    await api.network.post('/ping', formData: FormData.fromMap({'f': 'v'}));

    expect(api.last.body, isA<FormData>());
  });

  test('PUT merges caller headers over the defaults', () async {
    await api.network.put('/ping', data: {'x': 1}, headers: {'X-Extra': 'e'});

    expect(api.last.method, 'PUT');
    expect(api.last.headers['X-Extra'], 'e');
    expect(api.last.headers['Authorization'], 'Bearer token-123');
    expect(jsonDecode(api.last.body as String), {'x': 1});
  });

  test('PUT without extra headers and with form data', () async {
    await api.network.put('/ping', formData: FormData.fromMap({'f': 'v'}));

    expect(api.last.body, isA<FormData>());
  });

  test('DELETE and PATCH send their JSON bodies', () async {
    await api.network.delete('/ping', data: {'d': 1});
    expect(api.last.method, 'DELETE');
    expect(jsonDecode(api.last.body as String), {'d': 1});

    await api.network.patch('/ping', data: {'p': 2});
    expect(api.last.method, 'PATCH');
    expect(jsonDecode(api.last.body as String), {'p': 2});
  });

  test('explicit headers are accepted by get/post/patch/delete', () async {
    await api.network.get('/ping', headers: {'X-A': '1'});
    await api.network.post('/ping', headers: {'X-A': '1'}, data: {});
    await api.network.patch('/ping', headers: {'X-A': '1'}, data: {});
    await api.network.delete('/ping', headers: {'X-A': '1'}, data: {});

    expect(
        api.requests.map((r) => r.method), ['GET', 'POST', 'PATCH', 'DELETE']);
  });

  test('getBytes asks for a binary body', () async {
    api.onBytes('GET', '/file', [1, 2, 3]);

    final response =
        await api.network.getBytes('/file', queryParams: {'k': 'v'});

    expect(response.data, [1, 2, 3]);
    expect(api.last.headers['Accept'], '*/*');
    expect(api.last.headers['Authorization'], 'Bearer token-123');
  });

  test('getBytes and multipart calls omit auth when signed out', () async {
    final anon = StubApi(accessToken: '');
    anon.onBytes('GET', '/file', [9]);
    anon.on('POST', '/up', json: {});
    anon.on('PUT', '/up', json: {});

    await anon.network.getBytes('/file');
    await anon.network.postMultipart('/up', formData: FormData());
    await anon.network.putMultipart('/up', formData: FormData());

    expect(anon.requests.any((r) => r.headers.containsKey('Authorization')),
        isFalse);
  });

  test('multipart uploads keep the form data and send the token', () async {
    api.on('POST', '/up', json: {});
    api.on('PUT', '/up', json: {});
    final form = FormData.fromMap({'f': 'v'});

    await api.network.postMultipart('/up', formData: form);
    expect(api.last.method, 'POST');
    expect(api.last.body, isA<FormData>());
    expect(api.last.headers['Authorization'], 'Bearer token-123');

    await api.network
        .putMultipart('/up', formData: FormData.fromMap({'f': 'v'}));
    expect(api.last.method, 'PUT');
    expect(api.last.body, isA<FormData>());
  });

  test('a non-2xx answer surfaces as a DioException with the response',
      () async {
    api.on('GET', '/bad', status: 422, json: {'error': 'nope'});

    await expectLater(
      api.network.get('/bad'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 422)),
    );
  });

  test('the request/response/error interceptors pass everything through', () {
    // Exercised on a throwaway Dio so the logging branches run in debug mode.
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = api
      ..interceptors.add(interceptors);
    api.on('GET', '/ok', json: {'a': 1});
    api.onBytes('GET', '/bytes', [1]);
    api.on('GET', '/err', status: 500, json: {'e': 1});

    return Future(() async {
      expect((await dio.get('/ok')).data, {'a': 1});
      final bytes = await dio.get('/bytes',
          options: Options(responseType: ResponseType.bytes));
      expect(bytes.data, [1]);
      await expectLater(dio.get('/err'), throwsA(isA<DioException>()));
    });
  });
}
