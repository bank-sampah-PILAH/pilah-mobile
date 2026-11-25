import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_offset_tracker.dart';

/// A screen as the app draws it: a fixed bar on top, a scrolling body under it.
Widget _screen(ScrollOffsetTracker tracker, Widget body) => MaterialApp(
      home: tracker.track(
        Scaffold(appBar: AppBar(title: const Text('bar')), body: body),
      ),
    );

Widget _list(ScrollController controller) => ListView.builder(
      controller: controller,
      itemCount: 60,
      itemExtent: 100,
      itemBuilder: (_, i) => Text('row $i'),
    );

void main() {
  testWidgets('a tap on a scrolled list reports how far the list is scrolled', (
    tester,
  ) async {
    final tracker = ScrollOffsetTracker();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_screen(tracker, _list(controller)));

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 300));

    expect(controller.offset, greaterThan(400));
    expect(tracker.tapOffset, controller.offset);
  });

  testWidgets('a tap on the fixed bar reports 0 even when the list is scrolled', (
    tester,
  ) async {
    final tracker = ScrollOffsetTracker();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_screen(tracker, _list(controller)));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('bar'));

    expect(controller.offset, greaterThan(400));
    expect(tracker.tapOffset, 0);
  });
}
