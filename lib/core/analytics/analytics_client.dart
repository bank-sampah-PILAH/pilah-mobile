/// What analytics can do on this platform. Nothing is sent until [start].
abstract class AnalyticsClient {
  /// Whether this client can record on this platform. The consent dialog is
  /// only shown when it can, so nobody is told they are recorded when they
  /// are not.
  bool get isAvailable;

  Future<void> start();

  /// Stops recording, for example when the user withdraws their consent.
  Future<void> stop();
}

/// Used when analytics is off or not available on this platform.
class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  bool get isAvailable => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
