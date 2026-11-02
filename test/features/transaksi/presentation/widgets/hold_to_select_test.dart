import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/hold_to_select.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onSelected,
    VoidCallback? onTap,
    bool enabled = true,
    double bleed = 0,
  }) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HoldToSelect(
            enabled: enabled,
            bleed: bleed,
            onSelected: onSelected,
            child: InkWell(
              onTap: onTap ?? () {},
              child:
                  const SizedBox(width: 200, height: 60, child: Text('baris')),
            ),
          ),
        ),
      ));

  testWidgets('a half-second hold, like a long press, selects the row',
      (tester) async {
    var selected = 0;
    await pump(tester, onSelected: () => selected++);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 400));
    expect(selected, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(selected, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the green fill grows while holding and drains on release',
      (tester) async {
    await pump(tester, onSelected: () {});
    final fill = find.byKey(const ValueKey('hold-to-select-fill'));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.getSize(fill).width, closeTo(100, 10));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(fill).width, 0);
  });

  testWidgets(
      'releasing before the hold completes does not select, and a tap still taps',
      (tester) async {
    var selected = 0;
    var tapped = 0;
    await pump(tester, onSelected: () => selected++, onTap: () => tapped++);

    await tester.tap(find.text('baris'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    expect(selected, 0);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(selected, 0);
  });

  testWidgets('dragging away cancels the hold', (tester) async {
    var selected = 0;
    await pump(tester, onSelected: () => selected++);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(seconds: 3));
    expect(selected, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'the fill reaches past the row by the bleed, like the selected tint',
      (tester) async {
    await pump(tester, onSelected: () {}, bleed: 10);
    final box = tester.getRect(find.byType(SizedBox).first);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 250));

    final fill =
        tester.getRect(find.byKey(const ValueKey('hold-to-select-fill')));
    expect(fill.left, box.left - 10);
    expect(fill.width, closeTo((box.width + 20) / 2, 12));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a cancelled touch, such as a scroll taking over, never selects',
      (tester) async {
    var selected = 0;
    await pump(tester, onSelected: () => selected++);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.cancel();
    await tester.pump(const Duration(seconds: 3));

    expect(selected, 0);
  });

  testWidgets('a disabled row cannot be selected', (tester) async {
    var selected = 0;
    await pump(tester, onSelected: () => selected++, enabled: false);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('baris')));
    await tester.pump(); // the ticker starts on the next frame
    await tester.pump(const Duration(seconds: 3));
    expect(selected, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
