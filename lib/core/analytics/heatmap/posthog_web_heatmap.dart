import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_position_source.dart';
import 'package:web/web.dart' as web;

/// Makes posthog-js's heatmaps work for an app that scrolls inside a canvas.
///
/// posthog-js records a click at `clientY + the document's scroll`. Flutter
/// never scrolls the document, so every click would land on the first
/// screenful. This tells the library where the app's page is scrolled to.
class PosthogWebHeatmap {
  PosthogWebHeatmap({required this.scroll, required this.urls});

  final ScrollPositionSource scroll;
  final HeatmapUrlSanitizer urls;

  /// True while the browser is handling a click.
  bool _clicking = false;
  late final JSFunction _onClick = ((web.Event _) {
    _clicking = true;
    // The library reads the position while the click is handled, which is
    // before this timer fires.
    web.window.setTimeout((() => _clicking = false).toJS, 0.toJS);
  }).toJS;

  /// Replaces the library's scroll position with the app's. Call it once, after
  /// the library has been initialised.
  ///
  /// A click is placed by the list that was tapped, not by the one that is
  /// scrolled when the library gets to it. While the pointer hovers, the
  /// overlay of the toolbar follows the main list instead.
  void install(JSObject posthog) {
    // A listener on the window in the capture phase runs before the document
    // listener posthog-js uses for clicks, whatever order they were added in.
    web.window.addEventListener('click', _onClick, true.toJS);
    final manager = posthog.getProperty<JSObject>('scrollManager'.toJS);
    manager.setProperty(
      'scrollY'.toJS,
      (() => (_clicking ? scroll.tapOffset : scroll.liveOffset).toJS).toJS,
    );
  }

  void dispose() {
    web.window.removeEventListener('click', _onClick, true.toJS);
  }
}
