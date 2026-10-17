import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/master_detail_layout.dart';

import '../../support/pump_app.dart';

/// Every detail view in the Pengurus screens is currently a modal bottom
/// sheet. That is right on a phone and wrong on a 1440px monitor, where the
/// sheet slides up over a mostly-empty page and hides the list it came from.
///
/// This layout is the shared piece the other web tickets reuse: on a wide
/// window the detail sits beside the list, on a phone it does not appear
/// inline at all and the screen keeps using its existing sheet.
void main() {
  const master = Key('master');
  const detail = Key('detail');

  Future<void> mount(
    WidgetTester tester, {
    required Size window,
    bool withDetail = true,
  }) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: MasterDetailLayout(
          master: const SizedBox.expand(key: master),
          detail: withDetail ? const SizedBox.expand(key: detail) : null,
        ),
      ),
      size: window,
    );
  }

  group('MasterDetailLayout', () {
    testWidgets('a phone shows only the list', (tester) async {
      await mount(tester, window: const Size(390, 844));
      expect(find.byKey(master), findsOneWidget);
      expect(find.byKey(detail), findsNothing,
          reason: 'on compact the screen keeps using its bottom sheet');
    });

    testWidgets('a desktop window shows list and detail side by side',
        (tester) async {
      await mount(tester, window: const Size(1440, 900));
      expect(find.byKey(master), findsOneWidget);
      expect(find.byKey(detail), findsOneWidget);

      final masterRect = tester.getRect(find.byKey(master));
      final detailRect = tester.getRect(find.byKey(detail));
      expect(detailRect.left, greaterThanOrEqualTo(masterRect.right),
          reason: 'the panel sits beside the list, not over it');
    });

    testWidgets('a tablet also splits, since the rail already fits',
        (tester) async {
      await mount(tester, window: const Size(720, 900));
      expect(find.byKey(detail), findsOneWidget);
    });

    testWidgets('nothing selected leaves the list at full width',
        (tester) async {
      await mount(tester, window: const Size(1440, 900), withDetail: false);
      expect(find.byKey(detail), findsNothing);
      expect(tester.getSize(find.byKey(master)).width, 1440,
          reason: 'an empty panel must not steal width from the list');
    });

    testWidgets('the detail panel is narrower than the list', (tester) async {
      await mount(tester, window: const Size(1440, 900));
      final masterWidth = tester.getSize(find.byKey(master)).width;
      final detailWidth = tester.getSize(find.byKey(detail)).width;
      expect(masterWidth, greaterThan(detailWidth),
          reason: 'the list is the primary surface; the panel supports it');
    });

    testWidgets('resizing from desktop to phone hides the inline panel',
        (tester) async {
      await mount(tester, window: const Size(1440, 900));
      expect(find.byKey(detail), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();

      expect(find.byKey(detail), findsNothing);
      expect(find.byKey(master), findsOneWidget);
    });
  });
}
