import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/posthog_mobile_error_reporter.dart';

/// On Android and iOS errors go to PostHog's SDK; on any other platform
/// nothing is reported.
ErrorReporter createPlatformErrorReporter() {
  final native = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return native ? PosthogMobileErrorReporter() : const NoopErrorReporter();
}
