/// Starts and stops session recording. Nothing is recorded until [start].
abstract class AnalyticsClient {
  Future<void> start();
}

/// Used when analytics is off or not available on this platform.
class NoopAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> start() async {}
}
