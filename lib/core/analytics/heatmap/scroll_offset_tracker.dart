import 'package:flutter/widgets.dart';

/// Watches how far the app's lists are scrolled, so a heatmap can tell where on
/// the page a tap landed.
///
/// Flutter draws everything on one canvas and scrolls inside it, so the browser
/// never sees the page scroll. A tap's position on the screen alone would put
/// every tap on the first screenful.
class ScrollOffsetTracker {
  double _offset = 0;
  double _tapOffset = 0;

  /// How far the list under the last tap was scrolled.
  double get tapOffset => _tapOffset;

  /// Wraps [child] so that scrolls and taps below it are seen.
  Widget track(Widget child) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _offset = notification.metrics.pixels;
          }
          return false;
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _tapOffset = _offset,
          child: child,
        ),
      );
}
