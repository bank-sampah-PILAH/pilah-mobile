import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/web_exception_event_scrubber.dart';

/// Sends errors to PostHog's browser library, which is only there once the
/// pengurus has agreed to analytics (`PosthogWebClient` loads it on `start`).
///
/// The error is sent under its type name, as both name and message: a release
/// build shortens class names, and the message can hold what a pengurus typed
/// (a name, an amount), which no pattern can find. The naming (`ErrorTypeName.of`
/// in the app) is handed in, so this class needs no Flutter and its browser test
/// builds with `dart run test`.
class PosthogWebErrorReporter implements ErrorReporter {
  PosthogWebErrorReporter({required this.typeName});

  /// The stable name an error is filed under.
  final String Function(Object error) typeName;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    try {
      if (!globalContext.has('posthog')) return;
      final posthog = globalContext.getProperty<JSObject>('posthog'.toJS);

      final jsError = globalContext
          .getProperty<JSFunction>('Error'.toJS)
          .callAsConstructor<JSObject>(typeName(error).toJS);
      jsError.setProperty('name'.toJS, typeName(error).toJS);
      jsError.setProperty('stack'.toJS, stack.toString().toJS);

      final properties = <String, Object?>{
        ...AnalyticsProps.sanitize(context),
        if (!handled) webNotHandledMarker: false,
      };
      posthog.callMethod(
        'captureException'.toJS,
        jsError,
        properties.jsify(),
      );
    } catch (_) {
      // A failing library must never disturb the app.
    }
  }
}
