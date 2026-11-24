import 'package:pilah_mobile/core/errors/error_filter.dart';
import 'package:pilah_mobile/core/errors/error_flows.dart';
import 'package:pilah_mobile/core/errors/error_http.dart';
import 'package:pilah_mobile/core/errors/error_request_id.dart';

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

/// The version the app was built as (`--dart-define=APP_VERSION=...`), empty
/// for a build that was not given one.
const builtAppVersion = String.fromEnvironment('APP_VERSION');

/// Adds the screen, the core flow if there is one, the app version, and what
/// is known of the request that failed (its id, the status and the endpoint)
/// to every error, so the team knows where it happened without anyone listing
/// the screens by hand, and can find the call in the server's log.
class ContextualErrorReporter implements ErrorReporter {
  ContextualErrorReporter({
    required this.inner,
    required this.currentScreen,
    this.appVersion = builtAppVersion,
  });

  final ErrorReporter inner;

  /// The version this build carries; empty when it has none.
  final String appVersion;

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
    final requestId = ErrorRequestId.of(error);
    final status = ErrorHttp.statusOf(error);
    final path = ErrorHttp.pathOf(error);
    inner.report(
      error,
      stack,
      context: {
        if (screen != null) 'layar': screen,
        if (flow != null) 'alur': flow,
        if (requestId != null) 'id_permintaan': requestId,
        if (status != null) 'http_status': status,
        if (path != null) 'jalur_api': path,
        if (appVersion.isNotEmpty) 'versi_app': appVersion,
        ...context,
      },
      handled: handled,
    );
  }
}

/// Passes on a failed request once. The same failure is caught where it
/// arrives (the network layer) and again where it ends up (a global handler);
/// the team should see one error, not two. An error with no request id is
/// always passed on.
class DeduplicatingErrorReporter implements ErrorReporter {
  DeduplicatingErrorReporter({required this.inner, this.remember = 50});

  final ErrorReporter inner;

  /// How many request ids are kept; the oldest is forgotten first.
  final int remember;

  final _seen = <String>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    final id = ErrorRequestId.of(error);
    if (id != null) {
      if (_seen.contains(id)) return;
      _seen.add(id);
      if (_seen.length > remember) _seen.removeAt(0);
    }
    inner.report(error, stack, context: context, handled: handled);
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
