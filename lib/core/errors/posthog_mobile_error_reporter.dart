import 'dart:async';

import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Sends errors to PostHog's SDK on Android and iOS. The SDK is set up when
/// the pengurus agrees to analytics (`PosthogMobileClient.start`), and the
/// message of the error is cleaned in its `beforeSend` step.
class PosthogMobileErrorReporter implements ErrorReporter {
  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) {
    try {
      // "Not handled" can only be said through the SDK's zone-error call: it
      // wraps the error with how it was caught.
      final properties = AnalyticsProps.sanitize(context);
      final posthog = Posthog();
      unawaited(
        (handled
                ? posthog.captureException(
                    error: error,
                    stackTrace: stack,
                    properties: properties,
                  )
                : posthog.captureRunZonedGuardedError(
                    error: error,
                    stackTrace: stack,
                    properties: properties,
                  ))
            // A failing SDK must never disturb the app, not even later on.
            .catchError((Object _) {}),
      );
    } catch (_) {
      // The same, for a failure that comes straight away.
    }
  }
}
