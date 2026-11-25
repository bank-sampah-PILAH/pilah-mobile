import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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

  /// Wraps [child] so that scrolls and taps below it are seen.
  Widget track(Widget child) => NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          child: child,
        ),
      );

  bool _onScroll(ScrollNotification notification) {
    final context = notification.context;
    if (context != null && notification.metrics.axis == Axis.vertical) {
      _offsets[context] = notification.metrics.pixels;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _offsets.removeWhere((context, _) => !context.mounted);
    _tapOffset = _offsetAt(event.position);
  }

  double _offsetAt(Offset position) {
    var offset = 0.0;
    var smallest = double.infinity;
    for (final entry in _offsets.entries) {
      final box = entry.key.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final area = box.localToGlobal(Offset.zero) & box.size;
      if (!area.contains(position)) continue;
      final size = area.width * area.height;
      if (size < smallest) {
        smallest = size;
        offset = entry.value;
      }
    }
    return offset;
  }
}
