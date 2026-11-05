import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog for the Android and iOS apps.
///
/// The native SDK is not set up until [start], which only runs once the
/// pengurus has agreed, so nothing reaches PostHog before that. Everything the
/// SDK could collect on its own (app lifecycle events, screen recordings,
/// surveys, push tokens, crashes, feature flags) is switched off: only events
/// sent through [capture] and [screen] leave the app, and only with names
/// allowed by `AnalyticsProps`.
class PosthogMobileClient implements AnalyticsClient {
  /// [posthog] defaults to the SDK's own instance; tests pass one that runs on
  /// a fake platform so they never reach a device or the network.
  PosthogMobileClient({
    required this.apiKey,
    required this.host,
    this.environment,
    Posthog? posthog,
  }) : _posthog = posthog ?? Posthog();

  final String apiKey;
  final String host;

  /// `staging` or `production`: both share one PostHog project, so every event
  /// says which one it came from.
  final String? environment;
  final Posthog _posthog;

  Future<void>? _setup;

  /// Set up and not stopped: the only time events may leave the app.
  bool _live = false;

  /// Counts every stop, so a start that is still setting up knows whether a
  /// stop came after it and must win.
  int _stops = 0;

  @override
  bool get isAvailable => true;

  /// Starts the client. A failed start is not remembered: the next call tries
  /// again, and the error reaches the caller so it can be handled.
  @override
  Future<void> start() async {
    final stopsBefore = _stops;
    final setup = _setup ??= _setUp();
    try {
      await setup;
    } catch (_) {
      if (identical(_setup, setup)) _setup = null;
      rethrow;
    }
    // A stop that came while the SDK was setting up is the later decision.
    if (stopsBefore != _stops) return;
    // The SDK keeps an opt-out across app launches, so one made earlier would
    // still be in force. start() is only called once the pengurus has agreed.
    await _posthog.optIn();
    await _registerContext();
    if (stopsBefore == _stops) _live = true;
  }

  @override
  Future<void> stop() async {
    _stops++;
    _live = false;
    final setup = _setup;
    // Never started, so there is nothing to stop.
    if (setup == null) return;
    try {
      await setup;
    } catch (_) {
      // The SDK never came up, so nothing is running that could be stopped.
      // Failing here would stop a pengurus's withdrawal from being saved.
      return;
    }
    await _posthog.optOut();
  }

  @override
  void capture(String event, [Map<String, Object?> properties = const {}]) {
    if (!_live) return;
    _posthog.capture(
      eventName: event,
      properties: AnalyticsProps.sanitize(properties),
    );
  }

  @override
  void identify(String id) {
    final clean = AnalyticsProps.cleanId(id);
    if (!_live || clean == null) return;
    _posthog.identify(userId: clean);
  }

  @override
  void register(Map<String, Object?> properties) {
    if (!_live) return;
    for (final MapEntry(:key, :value)
        in AnalyticsProps.sanitize(properties).entries) {
      _posthog.register(key, value);
    }
  }

  @override
  void reset() {
    // Never set up: nothing was identified, so there is nothing to forget.
    if (_setup == null) return;
    _posthog.reset();
  }

  @override
  void screen(String name, [Map<String, Object?> properties = const {}]) {
    if (!_live) return;
    _posthog.screen(
      screenName: name,
      properties: AnalyticsProps.sanitize(properties),
    );
  }

  Future<void> _setUp() async {
    final config = PostHogConfig(apiKey)
      ..host = host
      ..optOut = true
      ..debug = false
      ..captureApplicationLifecycleEvents = false
      ..sessionReplay = false
      ..surveys = false
      ..preloadFeatureFlags = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false;
    await _posthog.setup(config);
  }

  /// Where this runs and which deployment it is, carried by every event after.
  /// The SDK forgets it when the user is forgotten (`reset`), so it is told on
  /// every start and not only the first.
  Future<void> _registerContext() async {
    for (final MapEntry(:key, :value) in AnalyticsProps.sanitize({
      'platform':
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      'environment': environment,
    }).entries) {
      await _posthog.register(key, value);
    }
  }
}
