import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';

import '../support/contrast.dart';

/// WCAG AA asks 4.5:1 for normal-size text.
const _aa = 4.5;

void main() {
  group('the primary green meets WCAG AA for normal text', () {
    const primary = AppColors.greenDark;
    final backgrounds = {
      'white': Colors.white,
      'card off-white': AppColors.cardOffWhite,
      'green tint': AppColors.greenLight,
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

  group('neutral text tokens meet WCAG AA', () {
    final surfaces = {
      'white': Colors.white,
      'surface': AppColors.surface,
      'fill': AppColors.fill,
    };
    for (final entry in surfaces.entries) {
      test('muted text on ${entry.key}', () {
        expect(contrast(AppColors.grey100, entry.value),
            greaterThanOrEqualTo(_aa));
      });
      test('soft ink on ${entry.key}', () {
        expect(contrast(AppColors.inkSoft, entry.value),
            greaterThanOrEqualTo(_aa));
      });
    }
  });

  group('the warning amber meets WCAG AA for normal text', () {
    const warning = AppColors.warning;
    final backgrounds = {
      'white': Colors.white,
      'surface': AppColors.surface,
      'warning tint': AppColors.warningLight,
    };
    for (final entry in backgrounds.entries) {
      test('as text on ${entry.key}', () {
        expect(contrast(warning, entry.value), greaterThanOrEqualTo(_aa));
      });
    }

    test('as a fill behind white text', () {
      expect(contrast(Colors.white, warning), greaterThanOrEqualTo(_aa));
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

  group('profile avatar fills meet WCAG AA behind white initials', () {
    test('there are several fills to pick from', () {
      expect(AppColors.avatarFills.length, greaterThan(1));
    });

    for (final fill in AppColors.avatarFills) {
      test('#${fill.toARGB32().toRadixString(16).substring(2)}', () {
        expect(contrast(Colors.white, fill), greaterThanOrEqualTo(_aa));
      });
    }
  });
}
