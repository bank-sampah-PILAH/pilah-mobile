import 'package:flutter/widgets.dart';
import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';
import 'package:pilah_mobile/core/analytics/heatmap/posthog_web_heatmap.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_offset_tracker.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';
import 'package:pilah_mobile/core/analytics/screen_recorder.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';
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
  /// [routePatterns] are the app's route patterns, such as `/nasabah/:id`: a
  /// heatmap is filed under them, and a screen that is not among them is not
  /// sent.
  PosthogWebRecordingClient({
    required String apiKey,
    required String host,
    String? environment,
    String? libraryUrl,
    Duration loadTimeout = const Duration(seconds: 15),
    List<String> routePatterns = const [],
    Posthog? posthog,
  }) : this._(
          apiKey: apiKey,
          host: host,
          environment: environment,
          libraryUrl: libraryUrl,
          loadTimeout: loadTimeout,
          routePatterns: routePatterns,
          posthog: posthog ?? Posthog(),
          scrollTracker: ScrollOffsetTracker(),
        );

  PosthogWebRecordingClient._({
    required super.apiKey,
    required super.host,
    required super.environment,
    required super.libraryUrl,
    required super.loadTimeout,
    required List<String> routePatterns,
    required Posthog posthog,
    required ScrollOffsetTracker scrollTracker,
  })  : _posthog = posthog,
        _scrollTracker = scrollTracker,
        super(
          recordScreen: true,
          heatmap: PosthogWebHeatmap(
            scroll: scrollTracker,
            urls: HeatmapUrlSanitizer(routePatterns),
          ),
        );

  final Posthog _posthog;
  final ScrollOffsetTracker _scrollTracker;
  Future<void>? _setup;

  /// The recorder looks at the app through [PostHogWidget], which reads the
  /// plugin's settings when it is first built, so it must not exist before
  /// [start] has set the plugin up.
  ///
  /// The tracker around it learns how far each list is scrolled, which the
  /// heatmap needs to place a click on the page.
  @override
  Widget wrapApp(Widget app) =>
      _setup == null ? app : _scrollTracker.track(PostHogWidget(child: app));

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
          ..sessionReplayConfig = maskedReplayConfig()
          ..surveys = false
          ..preloadFeatureFlags = false,
      );
}
