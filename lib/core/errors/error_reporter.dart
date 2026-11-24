import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// Tells the team about an error nobody expected. Screens and cubits never
/// call a monitoring service themselves: they go through this, so what leaves
/// the app, and whether anything does, is decided in one place.
abstract class ErrorReporter {
  /// Reports [error] with the [stack] it was thrown with. [context] holds
  /// extra facts such as the screen, and may only use names that
  /// `AnalyticsProps` allows. Never throws: a failure to report must not
  /// disturb the app.
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
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
  }) {}
}

/// Passes an error on only while the pengurus has agreed to analytics.
///
/// The consent controller is the only place that starts or stops analytics, so
/// this follows [AnalyticsClient.isRecording] instead of keeping a second
/// switch that could disagree with it.
class ConsentGatedErrorReporter implements ErrorReporter {
  ConsentGatedErrorReporter({required this.inner, required this.analytics});

  final ErrorReporter inner;
  final AnalyticsClient analytics;

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
  }) {
    if (!analytics.isRecording) return;
    inner.report(error, stack, context: context);
  }
}
