import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_position_source.dart';
import 'package:web/web.dart' as web;

/// Where `web/index.html` leaves the state of a toolbar launch link
/// (`#__posthog=...`) for [PosthogWebHeatmap.openToolbarIfLaunched]. It has to
/// be taken out of the address before the router starts, which is earlier than
/// any Dart code runs.
const toolbarLaunchStateKey = '__phToolbarState';

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
    // Flutter pages here scroll up and down only.
    manager.setProperty('scrollX'.toJS, (() => 0.toJS).toJS);
  }

  /// Opens PostHog's toolbar when the page was opened from its launch link, and
  /// does nothing on an ordinary visit.
  void openToolbarIfLaunched(JSObject posthog) {
    final state = globalContext.getProperty<JSAny?>(toolbarLaunchStateKey.toJS);
    if (state.isUndefinedOrNull) return;
    posthog.callMethod('loadToolbar'.toJS, state);
  }

  /// The `before_send` step for a heatmap event: its clicks are filed under the
  /// address they happened on, which can hold an id, so each address is
  /// replaced by the route pattern of its screen. Clicks on a screen the app
  /// does not know are dropped, and so are dead clicks, and so is an event left
  /// with nothing. Every other event passes untouched.
  JSAny? scrub(JSAny? captureResult) {
    if (captureResult == null) return null;
    try {
      final result = captureResult as JSObject;
      if (result.getProperty<JSAny?>('event'.toJS).dartify() != _heatmapEvent) {
        return captureResult;
      }
      final properties = result.getProperty<JSObject?>('properties'.toJS);
      final data = properties?.getProperty<JSObject?>(_dataKey.toJS);
      if (properties == null || data == null) return null;

      final byPattern = <String, List<JSAny?>>{};
      for (final address in _keysOf(data)) {
        final pattern = urls.sanitize(address);
        if (pattern == null) continue;
        final points = data.getProperty<JSArray<JSAny?>>(address.toJS).toDart;
        byPattern.putIfAbsent(pattern, () => []).addAll(points.where(_isKept));
      }
      byPattern.removeWhere((_, points) => points.isEmpty);
      if (byPattern.isEmpty) return null;

      final clean = JSObject();
      byPattern.forEach(
        (pattern, clicks) => clean.setProperty(pattern.toJS, clicks.toJS),
      );
      properties.setProperty(_dataKey.toJS, clean);
      return captureResult;
    } catch (_) {
      // A heatmap event in a shape nobody planned for may still carry an
      // address, so it is dropped rather than sent as it is.
      return null;
    }
  }

  /// A canvas has no page changes for the library to watch, so it takes every
  /// click for a dead one and its dead clicks say nothing.
  static bool _isKept(JSAny? point) =>
      (point as JSObject?)?.getProperty<JSAny?>('type'.toJS).dartify() !=
      'deadclick';

  static const _heatmapEvent = r'$$heatmap';
  static const _dataKey = r'$heatmap_data';

  static List<String> _keysOf(JSObject object) => globalContext
      .getProperty<JSObject>('Object'.toJS)
      .callMethod<JSArray<JSString>>('keys'.toJS, object)
      .toDart
      .map((key) => key.toDart)
      .toList();

  void dispose() {
    web.window.removeEventListener('click', _onClick, true.toJS);
  }
}
