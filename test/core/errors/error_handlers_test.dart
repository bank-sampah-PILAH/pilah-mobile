import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_handlers.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

class _RecordingReporter implements ErrorReporter {
  final reported = <({Object error, StackTrace stack})>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
  }) =>
      reported.add((error: error, stack: stack));
}

class _ThrowingReporter implements ErrorReporter {
  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
  }) =>
      throw StateError('the monitoring service is down');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? savedFlutterHandler;
  late ErrorCallback? savedDispatcherHandler;

  setUp(() {
    savedFlutterHandler = FlutterError.onError;
    savedDispatcherHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = savedFlutterHandler;
    PlatformDispatcher.instance.onError = savedDispatcherHandler;
  });

  group('ErrorHandlers.install', () {
    test('reports a Flutter framework error and still calls the old handler',
        () {
      final calls = <FlutterErrorDetails>[];
      FlutterError.onError = calls.add;
      final reporter = _RecordingReporter();
      ErrorHandlers.install(reporter);

      final error = StateError('build failed');
      final stack = StackTrace.current;
      FlutterError
          .onError!(FlutterErrorDetails(exception: error, stack: stack));

      expect(reporter.reported.single.error, error);
      expect(reporter.reported.single.stack, stack);
      expect(calls, hasLength(1), reason: 'the old handler still runs');
    });

    test('reports an error that reaches the platform dispatcher', () {
      PlatformDispatcher.instance.onError = null;
      final reporter = _RecordingReporter();
      ErrorHandlers.install(reporter);

      final error = StateError('async failure');
      PlatformDispatcher.instance.onError!(error, StackTrace.current);

      expect(reporter.reported.single.error, error);
    });

    test('a reporter that throws does not break the handlers', () {
      FlutterError.onError = (_) {};
      ErrorHandlers.install(_ThrowingReporter());

      expect(
        () => FlutterError.onError!(
          FlutterErrorDetails(exception: StateError('x')),
        ),
        returnsNormally,
      );
      expect(
        () => PlatformDispatcher.instance.onError!(
          StateError('x'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group('ErrorHandlers.runGuarded', () {
    test('reports an error thrown later inside the zone', () async {
      final reporter = _RecordingReporter();
      final done = Completer<void>();

      ErrorHandlers.runGuarded(reporter, () {
        Timer(Duration.zero, () {
          done.complete();
          throw StateError('thrown in a timer');
        });
      });
      await done.future;
      await Future<void>.delayed(Duration.zero);

      expect(reporter.reported.single.error, isA<StateError>());
    });
  });
}
