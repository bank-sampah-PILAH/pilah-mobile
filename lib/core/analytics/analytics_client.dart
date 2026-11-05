/// What analytics can do on this platform. Nothing is sent until [start].
abstract class AnalyticsClient {
  /// Whether this client can record on this platform. The consent dialog is
  /// only shown when it can, so nobody is told they are recorded when they
  /// are not.
  bool get isAvailable;

  /// Whether the screen is recorded as well as the steps taken. A consent
  /// given before recording existed does not cover it, and the dialog has to
  /// say so.
  bool get recordsScreen;

  Future<void> start();

  /// Stops recording, for example when the user withdraws their consent.
  Future<void> stop();

  /// Sends one event, such as `setoran_disimpan`. Does nothing before [start]
  /// or after [stop]. [properties] may only use the names in `AnalyticsProps`.
  void capture(String event, [Map<String, Object?> properties = const {}]);

  /// Tells analytics who the user is, by [id]: the id the backend gave them,
  /// never a name, email address or phone number. Everything sent afterwards
  /// belongs to that id. Does nothing before [start] or after [stop].
  void identify(String id);

  /// Properties that go with every event from now on, such as the user's role.
  /// Does nothing before [start] or after [stop].
  void register(Map<String, Object?> properties);

  /// Forgets who the user was, so whoever uses the device next is not tied to
  /// them. Works even after [stop], and does nothing if analytics never
  /// started.
  void reset();

  /// Reports that the user is now looking at [name], with optional
  /// [properties] such as the screen they came from. Does nothing before
  /// [start] or after [stop].
  void screen(String name, [Map<String, Object?> properties = const {}]);
}

/// Used when analytics is off or not available on this platform.
class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  bool get isAvailable => false;

  @override
  bool get recordsScreen => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void identify(String id) {}

  @override
  void register(Map<String, Object?> properties) {}

  @override
  void reset() {}

  @override
  void capture(String event, [Map<String, Object?> properties = const {}]) {}

  @override
  void screen(String name, [Map<String, Object?> properties = const {}]) {}
}
