import 'package:pilah_mobile/core/analytics/analytics_config.dart';

/// Picks the client for this platform: the no-op one when analytics is off.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) =>
    NoopAnalyticsClient();

/// Starts and stops session recording. Nothing is recorded until [start].
abstract class AnalyticsClient {
  Future<void> start();
}

/// Used when analytics is off or not available on this platform.
class NoopAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> start() async {}
}
