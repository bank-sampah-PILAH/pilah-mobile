import 'package:flutter/widgets.dart';

/// Watches how far the app's lists are scrolled, so a heatmap can tell where on
/// the page a tap landed.
///
/// Flutter draws everything on one canvas and scrolls inside it, so the browser
/// never sees the page scroll. A tap's position on the screen alone would put
/// every tap on the first screenful.
class ScrollOffsetTracker {
  /// The last vertical offset each scrollable reported.
  final Map<BuildContext, double> _offsets = {};
  double _tapOffset = 0;

  /// How far the list under the last tap was scrolled, or 0 when the tap landed
  /// on something that does not scroll (a bar, a dialog).
  double get tapOffset => _tapOffset;

  /// How far the main list of the screen (the largest one) is scrolled right
  /// now: what a heatmap overlay has to follow while the page scrolls.
  double get liveOffset {
    var offset = 0.0;
    var biggest = 0.0;
    for (final (:area, offset: scrolled) in _scrollables()) {
      final size = area.width * area.height;
      if (size > biggest) {
        biggest = size;
        offset = scrolled;
      }
    }
    return offset;
  }

  /// Wraps [child] so that scrolls and taps below it are seen.
  Widget track(Widget child) => NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            child: child,
          ),
        ),
      );

  /// A scrollable announces itself when it is laid out, so one that has not
  /// been scrolled yet is known too, at offset 0.
  bool _onMetrics(ScrollMetricsNotification notification) {
    _remember(notification.context, notification.metrics);
    return false;
  }

  bool _onScroll(ScrollNotification notification) {
    _remember(notification.context, notification.metrics);
    return false;
  }

  void _remember(BuildContext? context, ScrollMetrics metrics) {
    if (context != null && metrics.axis == Axis.vertical) {
      _offsets[context] = metrics.pixels;
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    var offset = 0.0;
    var smallest = double.infinity;
    for (final (:area, offset: scrolled) in _scrollables()) {
      if (!area.contains(event.position)) continue;
      final size = area.width * area.height;
      if (size < smallest) {
        smallest = size;
        offset = scrolled;
      }
    }
    _tapOffset = offset;
  }

  /// The scrollables that are on screen now, with where each one is drawn.
  Iterable<({Rect area, double offset})> _scrollables() sync* {
    _offsets.removeWhere((context, _) => !context.mounted);
    for (final entry in _offsets.entries) {
      final box = entry.key.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      yield (
        area: box.localToGlobal(Offset.zero) & box.size,
        offset: entry.value,
      );
    }
  }
}
