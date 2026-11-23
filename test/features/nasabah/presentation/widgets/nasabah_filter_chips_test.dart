import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';

void main() {
  Finder chip(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(AppChip),
      );

  testWidgets('the active tab is announced as the selected one',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: NasabahFilterChips(activeTab: true, onTabChanged: (_) {}),
      ),
    ));

    expect(
      tester.getSemantics(chip('Aktif')),
      isSemantics(
          label: 'Aktif',
          isButton: true,
          hasSelectedState: true,
          isSelected: true),
    );
    expect(
      tester.getSemantics(chip('Tidak Aktif')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    expect(
      tester.getSemantics(chip('Menunggu')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('tapping a tab reports its value', (tester) async {
    final tapped = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: NasabahFilterChips(activeTab: true, onTabChanged: tapped.add),
      ),
    ));

    await tester.tap(find.text('Tidak Aktif'));
    await tester.tap(find.text('Menunggu'));

    expect(tapped, [false, null]);
  });
}
