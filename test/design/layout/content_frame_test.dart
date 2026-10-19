import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

import '../../support/pump_app.dart';

/// A scrolling page on a wide window keeps its content to a readable column,
/// but the scroll view itself spans the body, so its scrollbar sits at the
/// window edge instead of floating in the middle of the screen.
void main() {
  const probe = Key('row');
  const list = Key('list');

  Widget page({double maxWidth = LayoutBreakpoint.contentMaxWidth}) =>
      ContentFrame(
        maxWidth: maxWidth,
        child: Builder(
          builder: (context) => ListView(
            key: list,
            padding: ContentFrame.insetOf(context).add(
              const EdgeInsets.symmetric(horizontal: 32),
            ),
            children: const [SizedBox(key: probe, height: 80)],
          ),
        ),
      );

  group('ContentFrame', () {
    testWidgets('has no inset on a phone or a tablet', (tester) async {
      for (final size in [const Size(390, 844), const Size(720, 900)]) {
        await pumpRouted(tester, page(), size: size);
        expect(tester.getSize(find.byKey(list)).width, size.width);
        expect(tester.getSize(find.byKey(probe)).width, size.width - 64);
      }
    });

    testWidgets('the scroll view spans the whole body on a wide window',
        (tester) async {
      await pumpRouted(tester, page(), size: const Size(1440, 900));

      expect(tester.getSize(find.byKey(list)).width, 1440,
          reason: 'so the scrollbar is at the window edge');
      expect(tester.getTopLeft(find.byKey(list)).dx, 0);
    });

    testWidgets('the content keeps the capped column, gutter included',
        (tester) async {
      await pumpRouted(tester, page(), size: const Size(1440, 900));

      final row = tester.getRect(find.byKey(probe));
      const column = LayoutBreakpoint.contentMaxWidth;
      expect(row.left, (1440 - column) / 2 + 32);
      expect(row.width, column - 64);
    });

    testWidgets('a form column is narrower and still centred', (tester) async {
      await pumpRouted(
        tester,
        page(maxWidth: LayoutBreakpoint.formMaxWidth),
        size: const Size(1440, 900),
      );

      final row = tester.getRect(find.byKey(probe));
      const column = LayoutBreakpoint.formMaxWidth;
      expect(row.left, (1440 - column) / 2 + 32);
      expect(row.width, column - 64);
    });

    testWidgets('measures the body, not the window (a rail takes room)',
        (tester) async {
      await pumpRouted(
        tester,
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(width: 1160, child: page()),
        ),
        size: const Size(1440, 900),
      );

      final row = tester.getRect(find.byKey(probe));
      expect(row.width, 1160 - 64,
          reason: 'narrower than the cap, so nothing is trimmed');
    });

    testWidgets('ContentInset pads a non-scrolling child the same way',
        (tester) async {
      await pumpRouted(
        tester,
        const ContentFrame(
          child: ContentInset(child: SizedBox.expand(key: probe)),
        ),
        size: const Size(1440, 900),
      );

      expect(tester.getSize(find.byKey(probe)).width,
          LayoutBreakpoint.contentMaxWidth);
    });
  });
}
