import 'package:pilah_mobile/core/errors/error_filter.dart';
import 'package:pilah_mobile/core/errors/error_flows.dart';

/// Tells the team about an error nobody expected. Screens and cubits never
/// call a monitoring service themselves: they go through this, so what leaves
/// the app, and whether anything does, is decided in one place.
abstract class ErrorReporter {
  /// Reports [error] with the [stack] it was thrown with. [context] holds
  /// extra facts such as the screen, and may only use names that
  /// `AnalyticsProps` allows. [handled] is false for an error nobody caught,
  /// which is what the global handlers report. Never throws: a failure to
  /// report must not disturb the app.
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  });
}

/// Used where errors are not reported: a build without monitoring, or a test.
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {}
}

/// Keeps the promise of [ErrorReporter.report], that it never throws, in one
/// place: whatever the reporters inside do, a failure to report is not allowed
/// to turn one error into two. Callers can rely on it instead of each guarding
/// the call themselves.
class SafeErrorReporter implements ErrorReporter {
  SafeErrorReporter(this.inner);

  final ErrorReporter inner;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    try {
      inner.report(error, stack, context: context, handled: handled);
    } catch (_) {
      // Nothing left to tell anyone.
    }
  }
}

/// Adds the screen, and the core flow if there is one, to every error, so the
/// team knows where it happened without anyone listing the screens by hand.
class ContextualErrorReporter implements ErrorReporter {
  ContextualErrorReporter({required this.inner, required this.currentScreen});

  final ErrorReporter inner;

  /// The name of the screen showing now (`AnalyticsScreenTracker.nameFor`), or
  /// null when there is none yet.
  final String? Function() currentScreen;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    final screen = currentScreen();
    final flow = screen == null ? null : ErrorFlows.nameFor(screen);
    inner.report(
      error,
      stack,
      context: {
        if (screen != null) 'layar': screen,
        if (flow != null) 'alur': flow,
        ...context,
      },
      handled: handled,
    );
  }
}

/// Passes on only the errors worth telling the team about; see [ErrorFilter].
class FilteredErrorReporter implements ErrorReporter {
  FilteredErrorReporter({required this.inner});

  final ErrorReporter inner;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    if (!ErrorFilter.shouldReport(error)) return;
    inner.report(error, stack, context: context, handled: handled);
  }
}

/// Stands in for a reporter that does not exist yet.
///
/// The error handlers have to be in place before the app has built its
/// services, and the real reporter is one of them. Until [resolve] finds it, an
/// error is dropped: nobody can have agreed to anything by then.
class LateErrorReporter implements ErrorReporter {
  LateErrorReporter(this.resolve);

  final ErrorReporter? Function() resolve;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) =>
      resolve()?.report(error, stack, context: context, handled: handled);
}

/// Passes an error on only while the pengurus has agreed to analytics.
///
/// The consent controller is the only place that starts or stops analytics, so
/// [allowed] should follow `AnalyticsClient.isRecording` instead of being a
/// second switch that could disagree with it. It is a function, like
/// `ContextualErrorReporter.currentScreen`, so this class needs to know nothing
/// else about analytics.
class ConsentGatedErrorReporter implements ErrorReporter {
  ConsentGatedErrorReporter({required this.inner, required this.allowed});

  final ErrorReporter inner;
  final bool Function() allowed;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    if (!allowed()) return;
    inner.report(error, stack, context: context, handled: handled);
  }
}
