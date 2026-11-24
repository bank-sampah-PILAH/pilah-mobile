import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

class _RecordingReporter implements ErrorReporter {
  final reported = <Object>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) =>
      reported.add(error);
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

void main() {
  group('FilteredErrorReporter', () {
    test('passes on an unexpected error but not a handled one', () {
      final inner = _RecordingReporter();
      final reporter = FilteredErrorReporter(inner: inner);
      final unexpected = StateError('boom');
      final handled = UnprocessableEntityException(
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
        ),
      );

      reporter.report(handled, StackTrace.current);
      reporter.report(unexpected, StackTrace.current);

      expect(inner.reported, [unexpected]);
    });
  });

  group('SafeErrorReporter', () {
    test('swallows a failure of the reporter inside, and passes the rest', () {
      final inner = _RecordingReporter();
      final safe = SafeErrorReporter(_ThrowingReporter());
      final fine = SafeErrorReporter(inner);
      final error = StateError('boom');

      expect(() => safe.report(error, StackTrace.current), returnsNormally);
      fine.report(error, StackTrace.current);

      expect(inner.reported, [error]);
    });
  });

  group('LateErrorReporter', () {
    test('drops errors until the real reporter exists, then forwards', () {
      final inner = _RecordingReporter();
      ErrorReporter? target;
      final reporter = LateErrorReporter(() => target);

      reporter.report(StateError('too early'), StackTrace.current);
      target = inner;
      final later = StateError('later');
      reporter.report(later, StackTrace.current);

      expect(inner.reported, [later]);
    });
  });
}
