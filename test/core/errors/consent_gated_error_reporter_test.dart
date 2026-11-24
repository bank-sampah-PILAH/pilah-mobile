import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

import '../../support/fake_analytics_client.dart';

class _RecordingReporter implements ErrorReporter {
  final reported = <Object>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
  }) =>
      reported.add(error);
}

void main() {
  group('ConsentGatedErrorReporter', () {
    test('reports nothing before analytics has started', () {
      final analytics = FakeAnalyticsClient();
      final inner = _RecordingReporter();
      final reporter = ConsentGatedErrorReporter(
          inner: inner, allowed: () => analytics.isRecording);

      reporter.report(StateError('boom'), StackTrace.current);

      expect(inner.reported, isEmpty);
    });

    test('passes the error on while analytics is recording', () async {
      final analytics = FakeAnalyticsClient();
      final inner = _RecordingReporter();
      final reporter = ConsentGatedErrorReporter(
          inner: inner, allowed: () => analytics.isRecording);

      await analytics.start();
      final error = StateError('boom');
      reporter.report(error, StackTrace.current);

      expect(inner.reported, [error]);
    });

    test('reports nothing again once analytics is stopped', () async {
      final analytics = FakeAnalyticsClient();
      final inner = _RecordingReporter();
      final reporter = ConsentGatedErrorReporter(
          inner: inner, allowed: () => analytics.isRecording);

      await analytics.start();
      await analytics.stop();
      reporter.report(StateError('boom'), StackTrace.current);

      expect(inner.reported, isEmpty);
    });
  });
}
