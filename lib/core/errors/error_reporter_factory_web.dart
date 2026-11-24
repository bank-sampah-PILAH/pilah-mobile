import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/posthog_web_error_reporter.dart';

/// On the web errors go to PostHog's browser library, once it is loaded.
ErrorReporter createPlatformErrorReporter() => PosthogWebErrorReporter();
