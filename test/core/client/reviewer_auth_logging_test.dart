import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import '../../support/stub_api.dart';

class _CaptureOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  test(
    'does not log reviewer credentials or the returned session tokens',
    () async {
      final output = _CaptureOutput();
      final defaultOutput = Logger.defaultOutput;
      addTearDown(() => Logger.defaultOutput = defaultOutput);
      Logger.defaultOutput = () => output;

      final api = StubApi();
      api.on(
        'POST',
        '/api/v1/auth/reviewer',
        json: {
          'access_token': 'private-access-token',
          'refresh_token': 'private-refresh-token',
          'user': {'email': 'reviewer@example.com'},
        },
      );
      await api.network.post(
        '/api/v1/auth/reviewer',
        data: {
          'email': 'reviewer@example.com',
          'password': 'private-reviewer-password',
        },
      );

      final logs = output.lines.join('\n');
      expect(logs, isNot(contains('reviewer@example.com')));
      expect(logs, isNot(contains('private-reviewer-password')));
      expect(logs, isNot(contains('private-access-token')));
      expect(logs, isNot(contains('private-refresh-token')));
    },
  );

  test('also redacts credentials when reviewer sign-in is rejected', () async {
    final output = _CaptureOutput();
    final defaultOutput = Logger.defaultOutput;
    addTearDown(() => Logger.defaultOutput = defaultOutput);
    Logger.defaultOutput = () => output;

    final api = StubApi();
    api.on(
      'POST',
      '/api/v1/auth/reviewer',
      status: 401,
      json: {'detail': 'private-reviewer-password'},
    );
    await expectLater(
      api.network.post(
        '/api/v1/auth/reviewer',
        data: {
          'email': 'reviewer@example.com',
          'password': 'private-reviewer-password',
        },
      ),
      throwsA(isA<DioException>()),
    );

    final logs = output.lines.join('\n');
    expect(logs, isNot(contains('reviewer@example.com')));
    expect(logs, isNot(contains('private-reviewer-password')));
  });
}
