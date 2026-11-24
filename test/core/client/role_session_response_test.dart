import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/pengurus_dikeluarkan.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/stub_api.dart';

void main() {
  test('a late old-role removal error cannot redirect the new session',
      () async {
    final api = StubApi(accessToken: 'old-access');
    api.latency = const Duration(milliseconds: 30);
    api.on('GET', '/private',
        status: 403,
        json: {'code': pengurusDikeluarkanCode, 'error': 'removed old role'});
    final signals = <String>[];
    final subscription = PengurusDikeluarkanSignal.stream.listen(signals.add);
    addTearDown(subscription.cancel);
    final request = api.network.get('/private');
    while (api.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await api.utils
        .setToken(accessToken: 'new-access', refreshToken: 'new-refresh');
    await expectLater(
        request,
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
    expect(signals, isEmpty);
  });

  test('a late old-role response cannot deliver its data after a switch',
      () async {
    final api = StubApi(accessToken: 'old-access');
    api.latency = const Duration(milliseconds: 30);
    api.on('GET', '/private', json: {'old-role-balance': 123});
    final request = api.network.get('/private');
    while (api.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await api.utils
        .setToken(accessToken: 'new-access', refreshToken: 'new-refresh');
    await expectLater(
        request,
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
  });
}
