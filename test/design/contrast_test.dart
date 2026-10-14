import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// WCAG AA asks 4.5:1 for normal-size text.
const _aa = 4.5;

void main() {
  group('the primary green meets WCAG AA for normal text', () {
    const primary = AppColors.greenDark;
    final backgrounds = {
      'white': Colors.white,
      'card off-white': AppColors.cardOffWhite,
      'green tint': AppColors.greenLight,
      'mint tint behind badges': const Color(0xFFF0FDF4),
    };

    for (final entry in backgrounds.entries) {
      test('as text on ${entry.key}', () {
        expect(contrast(primary, entry.value), greaterThanOrEqualTo(_aa));
      });
    }

    test('as a fill behind white text', () {
      expect(contrast(Colors.white, primary), greaterThanOrEqualTo(_aa));
    });
  });

  group('the danger red meets WCAG AA for normal text', () {
    const danger = AppColors.danger;

    test('as text on white', () {
      expect(contrast(danger, Colors.white), greaterThanOrEqualTo(_aa));
    });

    test('as text on its tint', () {
      expect(
          contrast(danger, AppColors.dangerLight), greaterThanOrEqualTo(_aa));
    });

    test('as a fill behind white text', () {
      expect(contrast(Colors.white, danger), greaterThanOrEqualTo(_aa));
    });
  });

  group('rendered buttons', () {
    Future<void> pump(WidgetTester tester, Widget button) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: Center(child: button)),
          ),
        );

    testWidgets('a FilledButton label is readable', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FilledButton(onPressed: () {}, child: const Text('Simpan Pengaturan')),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('a TextButton label is readable', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
