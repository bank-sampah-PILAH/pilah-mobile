import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

import '../../support/pump_app.dart';

/// `LayoutBreakpoint.fromWidth` is already covered as a pure function. What is
/// verified here is the part that can actually go wrong in a widget tree:
/// reading the width from the element's own `MediaQuery` so the value tracks a
/// window resize, rather than being sampled once at construction.
void main() {
  /// Pumps a probe at [size] and returns the breakpoint it resolved.
  Future<LayoutBreakpoint> resolvedAt(WidgetTester tester, Size size) async {
    late LayoutBreakpoint seen;
    await pumpRouted(
      tester,
      Builder(builder: (context) {
        seen = context.layoutBreakpoint;
        return const SizedBox.shrink();
      }),
      size: size,
    );
    return seen;
  }

  group('BuildContext.layoutBreakpoint', () {
    testWidgets('resolves compact on a phone-sized window', (tester) async {
      expect(await resolvedAt(tester, const Size(390, 844)),
          LayoutBreakpoint.compact);
    });

    testWidgets('resolves medium at exactly 600 logical pixels',
        (tester) async {
      expect(await resolvedAt(tester, const Size(600, 900)),
          LayoutBreakpoint.medium);
    });

    testWidgets('resolves expanded at exactly 840 logical pixels',
        (tester) async {
      expect(await resolvedAt(tester, const Size(840, 900)),
          LayoutBreakpoint.expanded);
    });

    testWidgets('resolves expanded on the desktop QA viewport', (tester) async {
      expect(await resolvedAt(tester, const Size(1440, 900)),
          LayoutBreakpoint.expanded);
    });

    testWidgets('tracks a window resize instead of sampling width once',
        (tester) async {
      final seen = <LayoutBreakpoint>[];
      await pumpRouted(
        tester,
        Builder(builder: (context) {
          seen.add(context.layoutBreakpoint);
          return const SizedBox.shrink();
        }),
        size: const Size(390, 844),
      );
      expect(seen.last, LayoutBreakpoint.compact);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();

      expect(seen.last, LayoutBreakpoint.expanded,
          reason: 'a resize past a boundary must re-resolve the breakpoint');
    });
  });
}
