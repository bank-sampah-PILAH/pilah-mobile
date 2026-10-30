import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

import '../../support/stub_api.dart';

class _RejectedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      message: 'private-error-message',
      error: const FormatException('private-error-source'),
      response: Response(
        requestOptions: options,
        statusCode: 503,
        data: {'error': 'private-response-customer'},
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<String> logs;
  late void Function(LogEvent) capture;

  setUp(() {
    logs = [];
    capture = (event) => logs.add(event.message.toString());
    Logger.addLogListener(capture);
  });
  tearDown(() => Logger.removeLogListener(capture));

  test('successful customer traffic logs metadata without credentials or PII',
      () async {
    final api = StubApi(accessToken: 'private-bearer-token');
    final responseBody = {
      'results': [
        {
          'nama': 'private-customer-name',
          'email': 'private-customer@example.test',
          'total_saldo': 'private-balance',
        }
      ],
      'access_token': 'private-access-token',
      'refresh_token': 'private-refresh-token',
    };
    api.on('POST', '/api/v1/nasabah', json: responseBody);
    final requestBody = {
      'profile': {'email': 'private-profile@example.test'},
      'id_token': 'private-id-token',
      'password': 'private-password',
    };
    final response = await api.network.post('/api/v1/nasabah',
        queryParams: {
          'search': 'private-search',
          'token': 'private-query-token'
        },
        headers: {
          'Authorization': 'Bearer private-bearer-token',
          'Cookie': 'private-cookie',
          'X-Customer': 'private-header',
        },
        data: requestBody);

    final output = logs.join('\n');
    expect(output, contains('[REDACTED]'));
    expect(output, contains('POST'));
    expect(output, contains('200'));
    expect(output, isNot(contains('private-')));
    expect(api.last.headers['Authorization'], 'Bearer private-bearer-token');
    expect(api.last.headers['Cookie'], 'private-cookie');
    expect(api.last.query['search'], 'private-search');
    expect(api.last.json, requestBody);
    expect(response.data, responseBody);
  });

  test('error logs omit raw diagnostics, response payload, and URL values',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _RejectedAdapter()
      ..interceptors.add(interceptors);
    await expectLater(
      dio.get('/private-path?search=private-url-search',
          options: Options(headers: {'Authorization': 'private-auth-header'})),
      throwsA(isA<DioException>()
          .having((error) => error.response?.statusCode, 'status', 503)),
    );
    final output = logs.join('\n');
    expect(output, contains('503'));
    expect(output, contains('badResponse'));
    expect(output, isNot(contains('private-')));
  });

  test('multipart and malformed bodies never reach the debug log', () async {
    final api = StubApi();
    api.on('POST', '/upload', json: {'ok': true});
    await api.network.postMultipart('/upload',
        formData: FormData.fromMap({
          'email': 'private-multipart@example.test',
          'file': MultipartFile.fromString('private-file-body',
              filename: 'private-file-name.txt'),
        }));
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = api
      ..interceptors.add(interceptors);
    await dio.post('/upload', data: '{"password":"private-malformed-json"');
    expect(logs.join('\n'), isNot(contains('private-')));
    expect(logs.join('\n'), contains('[REDACTED]'));
  });
}
