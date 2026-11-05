/// What analytics can do on this platform. Nothing is sent until [start].
abstract class AnalyticsClient {
  Future<void> start();
}

/// Used when analytics is off or not available on this platform.
class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  Future<void> start() async {}
}
