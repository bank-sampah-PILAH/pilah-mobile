import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import '../../support/stub_api.dart';

void main() {
  test('session credentials are redacted from successful and failed request logs', () async {
    final api = StubApi(accessToken: 'secret-bearer');
    api.on('POST', '/api/v1/auth/switch-role', json: {
      'access_token': 'secret-access', 'refresh_token': 'secret-refresh',
    });
    final logs = <String>[];
    void capture(LogEvent event) => logs.add(event.message.toString());
    Logger.addLogListener(capture);
    try {
      await api.network.post('/api/v1/auth/switch-role', data: {'role': 'nasabah'});
      api.on('POST', '/api/v1/auth/switch-role', status: 403,
        json: {'error': 'denied', 'refresh_token': 'secret-error'});
      await expectLater(api.network.post('/api/v1/auth/switch-role'),
        throwsA(isA<DioException>()));
    } finally {
      Logger.removeLogListener(capture);
    }
    final output = logs.join('\n');
    for (final secret in ['secret-bearer', 'secret-access', 'secret-refresh', 'secret-error']) {
      expect(output, isNot(contains(secret)));
    }
    expect(output, contains('[REDACTED]'));
  });
}
