import 'package:pilah_mobile/core/errors/error_handlers.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/services/di.dart';

/// Starts the app inside the error handlers, for both entrypoints.
///
/// The whole of the app has to start inside one zone, so an error thrown later
/// by a timer or a future nobody awaits is reported too: on the web it reaches
/// nothing else. The real reporter is one of the services [start] builds, so
/// until [resolve] finds it, errors are dropped: nobody can have agreed to
/// anything by then.
void runWithErrorReporting(
  void Function() start, {
  ErrorReporter? Function()? resolve,
}) {
  final reporter = SafeErrorReporter(
    LateErrorReporter(
      resolve ??
          () => di.isRegistered<ErrorReporter>() ? di<ErrorReporter>() : null,
    ),
  );
  ErrorHandlers.runGuarded(reporter, () {
    ErrorHandlers.install(reporter);
    start();
  });
}
