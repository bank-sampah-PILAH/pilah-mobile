import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

/// Input Space Partitioning over one characteristic: available layout width in
/// logical pixels. Three blocks, taken from the Material 3 window size classes
/// that Flutter itself targets, and corroborated by the existing
/// `NasabahStyle.maxWidth = 600` in the design system.
///
///   compact  w < 600          phone, keeps the bottom navigation
///   medium   600 <= w < 840   tablet
///   expanded w >= 840         desktop
///
/// Each boundary is checked from both sides, because `<` vs `<=` is the
/// off-by-one this code is most likely to get wrong.
void main() {
  group('LayoutBreakpoint.fromWidth', () {
    test('classifies a small phone as compact', () {
      expect(LayoutBreakpoint.fromWidth(320), LayoutBreakpoint.compact);
    });

    test('599 is still compact (off-point below the first boundary)', () {
      expect(LayoutBreakpoint.fromWidth(599), LayoutBreakpoint.compact);
    });

    test('600 is medium (on-point: the boundary belongs to medium)', () {
      expect(LayoutBreakpoint.fromWidth(600), LayoutBreakpoint.medium);
    });

    test('601 is medium (off-point above the first boundary)', () {
      expect(LayoutBreakpoint.fromWidth(601), LayoutBreakpoint.medium);
    });

    test('720 is medium (interior of the block)', () {
      expect(LayoutBreakpoint.fromWidth(720), LayoutBreakpoint.medium);
    });

    test('839 is still medium (off-point below the second boundary)', () {
      expect(LayoutBreakpoint.fromWidth(839), LayoutBreakpoint.medium);
    });

    test('840 is expanded (on-point: the boundary belongs to expanded)', () {
      expect(LayoutBreakpoint.fromWidth(840), LayoutBreakpoint.expanded);
    });

    test('841 is expanded (off-point above the second boundary)', () {
      expect(LayoutBreakpoint.fromWidth(841), LayoutBreakpoint.expanded);
    });

    test('a large monitor is expanded', () {
      expect(LayoutBreakpoint.fromWidth(2560), LayoutBreakpoint.expanded);
    });

    test('a degenerate zero width is compact rather than throwing', () {
      expect(LayoutBreakpoint.fromWidth(0), LayoutBreakpoint.compact);
    });
  });
}
