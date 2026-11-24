import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/error_scrubber.dart';
import 'package:pilah_mobile/core/errors/error_type_name.dart';

/// Sends errors to PostHog's browser library, which is only there once the
/// pengurus has agreed to analytics (`PosthogWebClient` loads it on `start`).
///
/// The message is cleaned and the type named by [ErrorTypeName] before the
/// library sees either, because release builds shorten class names and the
/// message can hold what a pengurus typed.
class PosthogWebErrorReporter implements ErrorReporter {
  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
  }) {
    try {
      if (!globalContext.has('posthog')) return;
      final posthog = globalContext.getProperty<JSObject>('posthog'.toJS);

      final jsError = globalContext
          .getProperty<JSFunction>('Error'.toJS)
          .callAsConstructor<JSObject>(
            ErrorScrubber.clean(error.toString()).toJS,
          );
      jsError.setProperty('name'.toJS, ErrorTypeName.of(error).toJS);
      jsError.setProperty('stack'.toJS, stack.toString().toJS);

      posthog.callMethod(
        'captureException'.toJS,
        jsError,
        AnalyticsProps.sanitize(context).jsify(),
      );
    } catch (_) {
      // A failing library must never disturb the app.
    }
  }
}
