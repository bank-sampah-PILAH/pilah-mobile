import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_position_source.dart';

/// Makes posthog-js's heatmaps work for an app that scrolls inside a canvas.
///
/// posthog-js records a click at `clientY + the document's scroll`. Flutter
/// never scrolls the document, so every click would land on the first
/// screenful. This tells the library where the app's page is scrolled to.
class PosthogWebHeatmap {
  PosthogWebHeatmap({required this.scroll, required this.urls});

  final ScrollPositionSource scroll;
  final HeatmapUrlSanitizer urls;

  /// Replaces the library's scroll position with the app's. Call it once, after
  /// the library has been initialised.
  void install(JSObject posthog) {
    final manager = posthog.getProperty<JSObject>('scrollManager'.toJS);
    manager.setProperty('scrollY'.toJS, (() => scroll.liveOffset.toJS).toJS);
  }

  void dispose() {}
}
