import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_bootstrap.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/services/di.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reports an error thrown later inside the app, once the reporter exists',
      () async {
    final reporter = _RecordingReporter();
    ErrorReporter? ready;
    final done = Completer<void>();

    runWithErrorReporting(
      () {
        Timer(Duration.zero, () {
          ready = reporter;
          done.complete();
          throw StateError('thrown in a timer');
        });
      },
      resolve: () => ready,
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);

    expect(reporter.reported.single, isA<StateError>());
  });

  test('finds the reporter in the service graph by default', () async {
    final reporter = _RecordingReporter();
    di.registerSingleton<ErrorReporter>(reporter);
    addTearDown(() => di.unregister<ErrorReporter>());
    final done = Completer<void>();

    runWithErrorReporting(() {
      Timer(Duration.zero, () {
        done.complete();
        throw StateError('thrown in a timer');
      });
    });
    await done.future;
    await Future<void>.delayed(Duration.zero);

    expect(reporter.reported.single, isA<StateError>());
  });

  test('drops an error that comes before the reporter exists', () async {
    final reporter = _RecordingReporter();
    final done = Completer<void>();

    runWithErrorReporting(
      () {
        Timer(Duration.zero, () {
          done.complete();
          throw StateError('too early');
        });
      },
      resolve: () => null,
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);

    expect(reporter.reported, isEmpty);
  });

  test('a resolver that fails does not raise a second error', () async {
    final done = Completer<void>();
    final uncaught = <Object>[];

    runZonedGuarded(() {
      runWithErrorReporting(
        () {
          Timer(Duration.zero, () {
            done.complete();
            throw StateError('x');
          });
        },
        resolve: () => throw StateError('the graph is not ready'),
      );
    }, (error, _) => uncaught.add(error));
    await done.future;
    await Future<void>.delayed(Duration.zero);

    expect(uncaught, isEmpty);
  });
}
