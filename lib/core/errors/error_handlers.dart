import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

/// Connects the places Flutter reports an error nobody caught to an
/// [ErrorReporter].
///
/// There are three, and none of them sees what the others do. On the web in
/// particular, an error thrown later (a timer, a future nobody awaits) reaches
/// neither `FlutterError.onError` nor the platform dispatcher: only the zone it
/// was started in hears about it.
abstract final class ErrorHandlers {
  /// Reports framework errors and errors that reach the platform dispatcher.
  /// Whatever handled them before still does, so the console output stays.
  static void install(ErrorReporter reporter) {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      _report(reporter, details.exception, details.stack);
      if (previousFlutter != null) {
        previousFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final dispatcher = PlatformDispatcher.instance;
    final previousDispatcher = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      _report(reporter, error, stack);
      return previousDispatcher?.call(error, stack) ?? false;
    };
  }

  /// Runs [body] in a zone that reports every error thrown inside it later on.
  /// Everything the app starts has to start inside it, which is why the whole
  /// of `main` goes in here.
  static void runGuarded(ErrorReporter reporter, void Function() body) {
    runZonedGuarded(body, (error, stack) {
      _report(reporter, error, stack);
      debugPrint('Uncaught error: $error\n$stack');
    });
  }

  /// Reporting is the last thing that may go wrong: whatever the reporter does,
  /// it must not turn one error into two.
  static void _report(ErrorReporter reporter, Object error, StackTrace? stack) {
    try {
      reporter.report(error, stack ?? StackTrace.current);
    } catch (_) {
      // Nothing left to tell anyone.
    }
  }
}
