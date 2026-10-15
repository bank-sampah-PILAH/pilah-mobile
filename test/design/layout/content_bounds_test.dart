import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

import '../../support/pump_app.dart';

/// On a phone the content should use every pixel it has. On a wide monitor it
/// should not: a line of text spanning 1440 logical pixels is hard to read, so
/// the content is capped and centred, leaving the page background either side.
void main() {
  const probe = Key('content');

  Future<Size> childSizeAt(WidgetTester tester, Size window) async {
    await pumpRouted(
      tester,
      const ContentBounds(child: SizedBox.expand(key: probe)),
      size: window,
    );
    return tester.getSize(find.byKey(probe));
  }

  group('ContentBounds', () {
    testWidgets('fills the whole width on a phone', (tester) async {
      final size = await childSizeAt(tester, const Size(390, 844));
      expect(size.width, 390);
    });

    testWidgets('still fills the whole width on a tablet', (tester) async {
      final size = await childSizeAt(tester, const Size(720, 900));
      expect(size.width, 720);
    });

    testWidgets('caps the width on a wide desktop window', (tester) async {
      final size = await childSizeAt(tester, const Size(1440, 900));
      expect(size.width, LayoutBreakpoint.contentMaxWidth);
    });

    testWidgets('centres the content once it is capped', (tester) async {
      await pumpRouted(
        tester,
        const ContentBounds(child: SizedBox.expand(key: probe)),
        size: const Size(1440, 900),
      );
      final left = tester.getTopLeft(find.byKey(probe)).dx;
      expect(left, (1440 - LayoutBreakpoint.contentMaxWidth) / 2,
          reason: 'equal gutters either side');
    });

    testWidgets('does not pad a window narrower than the cap', (tester) async {
      // 1000 is expanded (>= 840) but still below the 1200 cap, so capping
      // must not invent a gutter that shrinks the content.
      final size = await childSizeAt(tester, const Size(1000, 900));
      expect(size.width, 1000);
    });
  });
}
