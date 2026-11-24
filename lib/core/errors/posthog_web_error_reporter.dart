import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/web_exception_event_scrubber.dart';

/// Sends errors to PostHog's browser library, which is only there once the
/// pengurus has agreed to analytics (`PosthogWebClient` loads it on `start`).
///
/// The message is cleaned and the type named before the library sees either,
/// because release builds shorten class names and the message can hold what a
/// pengurus typed. Those two steps are handed in (`ErrorMessage.of` and
/// `ErrorTypeName.of` in the app), so this class needs no Flutter and its
/// browser test builds with `dart run test`.
class PosthogWebErrorReporter implements ErrorReporter {
  PosthogWebErrorReporter({required this.typeName, required this.message});

  /// The stable name an error is filed under.
  final String Function(Object error) typeName;

  /// The cleaned text sent with an error.
  final String Function(Object error) message;

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
          .callAsConstructor<JSObject>(message(error).toJS);
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
