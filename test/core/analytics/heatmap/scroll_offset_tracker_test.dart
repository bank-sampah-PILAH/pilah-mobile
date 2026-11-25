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

  testWidgets('a tap on the fixed bar reports 0 even when the list is scrolled',
      (
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

  testWidgets('the live offset follows the main list while nothing is tapped', (
    tester,
  ) async {
    final tracker = ScrollOffsetTracker();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_screen(tracker, _list(controller)));
    expect(tracker.liveOffset, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tracker.liveOffset, controller.offset);
  });

  testWidgets('a tap on a scrolling column (not a list) reports its offset', (
    tester,
  ) async {
    final tracker = ScrollOffsetTracker();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _screen(
        tracker,
        SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(
                    width: double.infinity, height: 100, child: Text('row $i'))
            ],
          ),
        ),
      ),
    );
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 300));

    expect(controller.offset, greaterThan(400));
    expect(tracker.tapOffset, controller.offset);
    expect(tracker.liveOffset, controller.offset);
  });

  testWidgets(
      'a tap on a small list inside a scrolled page reports the inner offset', (
    tester,
  ) async {
    final tracker = ScrollOffsetTracker();
    final page = ScrollController();
    final inner = ScrollController();
    addTearDown(page.dispose);
    addTearDown(inner.dispose);
    await tester.pumpWidget(
      _screen(
        tracker,
        SingleChildScrollView(
          controller: page,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  controller: inner,
                  itemCount: 40,
                  itemExtent: 50,
                  itemBuilder: (_, i) => Text('inner $i'),
                ),
              ),
              for (var i = 0; i < 30; i++)
                SizedBox(
                    width: double.infinity, height: 100, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 150));

    expect(inner.offset, greaterThan(100));
    expect(tracker.tapOffset, inner.offset);
    // The overlay follows the page, not the little list.
    expect(tracker.liveOffset, page.offset);
  });
}
