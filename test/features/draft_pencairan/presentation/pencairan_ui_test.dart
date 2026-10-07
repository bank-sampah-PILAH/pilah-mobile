import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

import '../../../support/pump_app.dart';

/// The look of Catat Pencairan, shared by the draft screens: a grey rounded
/// back button, bold title, spaced grey section labels, white 12px inputs,
/// pill chips, and soft cards.
void main() {
  group('PencairanHeader', () {
    testWidgets('shows the title and a grey rounded back button that goes back',
        (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(
          body: SafeArea(child: PencairanHeader(title: 'Pencairan')),
        ),
        pushed: true,
      );

      expect(find.text('Pencairan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      final box = tester.widget<Container>(find.descendant(
        of: find.byKey(const Key('kembali')),
        matching: find.byType(Container),
      ));
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, Colors.grey[100]);
      expect(decoration.borderRadius, BorderRadius.circular(12));

      await tester.tap(find.byKey(const Key('kembali')));
      await tester.pumpAndSettle();

      expect(find.text('Pencairan'), findsNothing);
      expect(find.text('route:/'), findsOneWidget);
    });

    testWidgets('puts trailing actions at the right', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(
          body: SafeArea(
            child: PencairanHeader(
              title: 'Pencairan',
              actions: [Icon(Icons.more_vert, key: Key('aksi'))],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('aksi')), findsOneWidget);
      expect(tester.getCenter(find.byKey(const Key('aksi'))).dx,
          greaterThan(tester.getCenter(find.text('Pencairan')).dx));
    });
  });

  testWidgets('SectionLabel is small, bold, spaced and grey', (tester) async {
    await pumpRouted(tester, const Scaffold(body: SectionLabel('NOMINAL')));

    final style = tester.widget<Text>(find.text('NOMINAL')).style!;
    expect(style.fontSize, 10);
    expect(style.fontWeight, FontWeight.bold);
    expect(style.letterSpacing, 1.0);
    expect(style.color, Colors.grey[500]);
  });

  test('inputs are white, 12px round, grey until focused, then green', () {
    final decoration = pencairanInputDecoration(hintText: 'Contoh: 50000');

    expect(decoration.hintText, 'Contoh: 50000');
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, Colors.white);
    final enabled = decoration.enabledBorder! as OutlineInputBorder;
    expect(enabled.borderRadius, BorderRadius.circular(12));
    expect(enabled.borderSide.color, Colors.grey[300]);
    final focused = decoration.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.color, AppColors.greenDark);
    expect(focused.borderSide.width, 1.5);
    final error = decoration.errorBorder! as OutlineInputBorder;
    expect(error.borderSide.color, Colors.red);
  });

  group('PencairanChip', () {
    Future<void> pumpChip(WidgetTester tester, {required bool selected}) =>
        pumpRouted(
          tester,
          Scaffold(
            body: PencairanChip(
              key: const Key('chip'),
              label: 'Tunai',
              selected: selected,
              onTap: () {},
            ),
          ),
        );

    testWidgets('is solid green with white text when selected', (tester) async {
      await pumpChip(tester, selected: true);

      final box = tester.widget<Container>(find.descendant(
          of: find.byKey(const Key('chip')), matching: find.byType(Container)));
      expect((box.decoration! as BoxDecoration).color, AppColors.greenDark);
      expect(
          tester.widget<Text>(find.text('Tunai')).style!.color, Colors.white);
    });

    testWidgets('is light grey when not selected, and reports taps',
        (tester) async {
      var taps = 0;
      await pumpRouted(
        tester,
        Scaffold(
          body: PencairanChip(
            key: const Key('chip'),
            label: 'Tunai',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );

      final box = tester.widget<Container>(find.descendant(
          of: find.byKey(const Key('chip')), matching: find.byType(Container)));
      expect((box.decoration! as BoxDecoration).color, const Color(0xFFF3F4F6));
      await tester.tap(find.byKey(const Key('chip')));
      expect(taps, 1);
    });
  });

  testWidgets('PencairanSummaryCard lists rows and stresses the last',
      (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(
        body: PencairanSummaryCard(rows: [
          SummaryRow(label: 'Total pencairan', value: 'Rp 100.000'),
          SummaryRow(
              label: 'Total dibayar', value: 'Rp 90.000', emphasized: true),
        ]),
      ),
    );

    expect(find.text('Total pencairan'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(tester.widget<Text>(find.text('Rp 90.000')).style!.fontSize, 20);
    expect(tester.widget<Text>(find.text('Rp 100.000')).style!.fontSize, 15);
  });

  testWidgets('PencairanCard is a soft grey rounded box', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: PencairanCard(child: Text('isi'))),
    );

    final box = tester.widget<Container>(find.descendant(
        of: find.byType(PencairanCard), matching: find.byType(Container)));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.grey[50]);
    expect(decoration.borderRadius, BorderRadius.circular(16));
  });
}
