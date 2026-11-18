import 'package:flutter/widgets.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';
import 'package:pilah_mobile/core/analytics/screen_recorder.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// [PosthogWebClient] that also records the screen, with every text and image
/// masked.
///
/// Flutter draws the whole app on one canvas, so the browser library records a
/// picture of it. The plugin supplies the rectangles to cover: it walks the
/// widget tree, covers every text and image, and leaves uncovered only what
/// `RevealInReplay` names. Anything the plugin cannot describe is skipped, not
/// sent. The plugin hooks into the library that is already running, so it is
/// set up only after the library has been initialised.
class PosthogWebRecordingClient extends PosthogWebClient
    implements ScreenRecorder {
  PosthogWebRecordingClient({
    required super.apiKey,
    required super.host,
    super.environment,
    super.libraryUrl,
    super.loadTimeout,
    Posthog? posthog,
  })  : _posthog = posthog ?? Posthog(),
        super(recordScreen: true);

  final Posthog _posthog;
  Future<void>? _setup;

  /// The recorder looks at the app through [PostHogWidget], which reads the
  /// plugin's settings when it is first built, so it must not exist before
  /// [start] has set the plugin up.
  @override
  Widget wrapApp(Widget app) =>
      _setup == null ? app : PostHogWidget(child: app);

  @override
  Future<void> start() async {
    await super.start();
    final setup = _setup ??= _setUp();
    try {
      await setup;
    } catch (_) {
      if (identical(_setup, setup)) _setup = null;
      rethrow;
    }
  }

  Future<void> _setUp() => _posthog.setup(
        PostHogConfig(apiKey)
          ..host = host
          ..debug = false
          ..captureApplicationLifecycleEvents = false
          ..sessionReplay = true
          ..sessionReplayConfig = (PostHogSessionReplayConfig()
            ..maskAllTexts = true
            ..maskAllImages = true)
          ..surveys = false
          ..preloadFeatureFlags = false,
      );
}
