import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import '../../support/contrast.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';

Widget _host(Widget chip) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: chip)),
    );

void main() {
  testWidgets('is a pill, both for its fill and for its ripple',
      (tester) async {
    await tester.pumpWidget(
      _host(AppChip(label: 'Aktif', selected: true, onTap: () {})),
    );

    final pill = BorderRadius.circular(AppRadius.pill);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppChip),
        matching: find.byType(Material),
      ),
    );
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect([material.borderRadius, ink.borderRadius], [pill, pill]);
  });

  testWidgets('a selected chip tells screen readers it is a selected button',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(AppChip(label: 'Aktif', selected: true, onTap: () {})),
    );

    expect(
      tester.getSemantics(find.byType(AppChip)),
      isSemantics(
        label: 'Aktif',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('an unselected chip says it is not selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(AppChip(label: 'Tidak Aktif', selected: false, onTap: () {})),
    );

    expect(
      tester.getSemantics(find.byType(AppChip)),
      isSemantics(
        label: 'Tidak Aktif',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('a count is read together with the label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(AppChip(label: 'Semua', selected: false, count: 4, onTap: () {})),
    );

    expect(
      tester.getSemantics(find.byType(AppChip)),
      isSemantics(label: 'Semua, 4'),
    );
    handle.dispose();
  });

  testWidgets('meets the tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(AppChip(label: 'Pencairan', selected: false, onTap: () {})),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(AppChip(label: 'Setoran', selected: false, onTap: () => taps++)),
    );

    await tester.tap(find.text('Setoran'));

    expect(taps, 1);
  });

  group('on a coloured header', () {
    testWidgets('a selected pill is white and an unselected one reads white',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Container(
            color: AppColors.greenDark,
            child: Row(children: [
              AppChip.onColor(label: 'Menunggu', selected: true, onTap: () {}),
              AppChip.onColor(
                  label: 'Disetujui', selected: false, onTap: () {}),
            ]),
          ),
        ),
      ));

      Material pill(String label) => tester.widget<Material>(find.descendant(
            of: find.ancestor(
                of: find.text(label), matching: find.byType(AppChip)),
            matching: find.byType(Material),
          ));
      expect(pill('Menunggu').color, Colors.white);
      expect(tester.widget<Text>(find.text('Menunggu')).style!.color,
          AppColors.greenDark);
      expect(tester.widget<Text>(find.text('Disetujui')).style!.color,
          Colors.white);
    });

    testWidgets('the unselected label is readable on the green header',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Container(
            color: AppColors.greenDark,
            child: AppChip.onColor(
                label: 'Disetujui', selected: false, onTap: () {}),
          ),
        ),
      ));

      final pill = tester.widget<Material>(find.descendant(
          of: find.byType(AppChip), matching: find.byType(Material)));
      final blended = Color.alphaBlend(pill.color!, AppColors.greenDark);
      expect(contrast(Colors.white, blended), greaterThanOrEqualTo(4.5));
    });
  });
}
