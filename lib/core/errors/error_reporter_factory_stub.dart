import 'package:pilah_mobile/core/errors/error_reporter.dart';

/// Off the web nothing reports errors yet.
ErrorReporter createPlatformErrorReporter() => const NoopErrorReporter();
