import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
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

  group('PencairanPopupMenu', () {
    Future<List<String>> pump(WidgetTester tester) async {
      final dipilih = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: PencairanPopupMenu<String>(
              key: const Key('menu'),
              onSelected: dipilih.add,
              entries: const [
                PencairanMenuEntry(
                  key: Key('aksi-satu'),
                  value: 'satu',
                  label: 'Aksi satu',
                  icon: Icons.restart_alt,
                ),
                PencairanMenuEntry(
                  key: Key('aksi-dua'),
                  value: 'dua',
                  label: 'Aksi dua',
                  icon: Icons.delete_outline,
                  destruktif: true,
                ),
              ],
            ),
          ),
        ),
      ));
      return dipilih;
    }

    testWidgets('shows the three dots and opens a white rounded card',
        (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu')));
      await tester.pumpAndSettle();

      final kartu = tester.widget<Material>(find
          .ancestor(
              of: find.byKey(const Key('aksi-satu')),
              matching: find.byType(Material))
          .first);
      expect(kartu.color, Colors.white);
      expect(kartu.surfaceTintColor, Colors.transparent);
      final bentuk = kartu.shape! as RoundedRectangleBorder;
      expect(bentuk.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('each row carries the icon of its action', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('menu')));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
              of: find.byKey(const Key('aksi-satu')),
              matching: find.byIcon(Icons.restart_alt)),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('aksi-dua')),
              matching: find.byIcon(Icons.delete_outline)),
          findsOneWidget);
      expect(find.text('Aksi satu'), findsOneWidget);
      expect(find.text('Aksi dua'), findsOneWidget);
    });

    testWidgets('a destructive action reads red, the others green',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('menu')));
      await tester.pumpAndSettle();

      Color warna(String key, IconData icon) => tester
          .widget<Icon>(find.descendant(
              of: find.byKey(Key(key)), matching: find.byIcon(icon)))
          .color!;
      expect(warna('aksi-satu', Icons.restart_alt), AppColors.greenDark);
      expect(warna('aksi-dua', Icons.delete_outline), const Color(0xFFC62828));
    });

    testWidgets('choosing a row reports its value and closes the card',
        (tester) async {
      final dipilih = await pump(tester);
      await tester.tap(find.byKey(const Key('menu')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('aksi-dua')));
      await tester.pumpAndSettle();

      expect(dipilih, ['dua']);
      expect(find.byKey(const Key('aksi-satu')), findsNothing);
    });
  });

  group('SectionLabel', () {
    testWidgets('a heading is dark, bold and spaced so it stands out',
        (tester) async {
      await pumpRouted(tester, const Scaffold(body: SectionLabel('RINGKASAN')));

      final style = tester.widget<Text>(find.text('RINGKASAN')).style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.letterSpacing, 1.0);
      expect(style.color, Colors.black87);
    });

    testWidgets('a field label is a step quieter: smaller, dark grey',
        (tester) async {
      await pumpRouted(
          tester, const Scaffold(body: SectionLabel.field('NOMINAL')));

      final style = tester.widget<Text>(find.text('NOMINAL')).style!;
      expect(style.fontSize, 11);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.letterSpacing, 1.0);
      expect(style.color, Colors.grey[700]);
    });
  });

  group('PencairanAvatar', () {
    testWidgets('shows the initials on the name\'s own palette colour',
        (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(
          body: PencairanAvatar(key: Key('avatar'), nama: 'Ahmad Ridwan'),
        ),
      );

      expect(find.text('AR'), findsOneWidget);
      final box = tester.widget<Container>(find.descendant(
          of: find.byKey(const Key('avatar')),
          matching: find.byType(Container)));
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, avatarPaletteFor('Ahmad Ridwan').$1);
      expect(tester.widget<Text>(find.text('AR')).style!.color,
          avatarPaletteFor('Ahmad Ridwan').$2);
      expect(
          tester.getSize(find.byKey(const Key('avatar'))), const Size(40, 40));
    });
  });

  testWidgets('PencairanMetaLine reads label, name and time in two tones',
      (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(
        body: PencairanMetaLine(
          label: 'Dibuat oleh',
          nama: 'Pengurus PILAH',
          waktu: '8 Okt 2026, 06:59',
        ),
      ),
    );

    expect(find.text('Dibuat oleh Pengurus PILAH · 8 Okt 2026, 06:59'),
        findsOneWidget);
    final text = tester.widget<Text>(find.byType(Text));
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans[0].style!.color, Colors.grey[700]);
    expect(spans[1].text, 'Pengurus PILAH');
    expect(spans[1].style!.color, Colors.black87);
    expect(spans[1].style!.fontWeight, FontWeight.w600);
    expect(spans[2].style!.color, Colors.grey[700]);
  });

  testWidgets('PencairanChip can carry an icon', (tester) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PencairanChip(
          key: const Key('chip'),
          label: 'Tunai',
          icon: Icons.payments_outlined,
          selected: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.payments_outlined)).color,
        Colors.white);
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

  testWidgets('PencairanCard is a white rounded box with a green outline',
      (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: PencairanCard(child: Text('isi'))),
    );

    final box = tester.widget<Container>(find.descendant(
        of: find.byType(PencairanCard), matching: find.byType(Container)));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.borderRadius, BorderRadius.circular(16));
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.greenDark);
    expect(border.top.width, 2);
  });

  group('PencairanCard.shadow', () {
    BoxDecoration decorationOf(WidgetTester tester) => tester
        .widget<Container>(find.descendant(
            of: find.byType(PencairanCard), matching: find.byType(Container)))
        .decoration! as BoxDecoration;

    testWidgets('is white with a soft shadow and no outline', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: PencairanCard.shadow(child: Text('isi'))),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNull);
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('can still be outlined, to mark an error or a selection',
        (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(
          body: PencairanCard.shadow(
            borderColor: AppColors.greenDark,
            child: Text('isi'),
          ),
        ),
      );

      final decoration = decorationOf(tester);
      expect((decoration.border! as Border).top.color, AppColors.greenDark);
      expect((decoration.border! as Border).top.width, 2);
      expect(decoration.boxShadow, isNotEmpty);
    });
  });

  testWidgets('a PencairanCard can take another outline, for an error',
      (tester) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PencairanCard(
            borderColor: Colors.red.shade300, child: const Text('isi')),
      ),
    );

    final box = tester.widget<Container>(find.descendant(
        of: find.byType(PencairanCard), matching: find.byType(Container)));
    expect(((box.decoration! as BoxDecoration).border! as Border).top.color,
        Colors.red.shade300);
  });

  group('PencairanActionButton', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool filled,
      VoidCallback? onPressed,
      bool isLoading = false,
      double width = 200,
      String label = 'Simpan Draft',
    }) =>
        pumpRouted(
          tester,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: PencairanActionButton(
                  key: const Key('aksi'),
                  label: label,
                  icon: Icons.save_outlined,
                  filled: filled,
                  isLoading: isLoading,
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        );

    testWidgets('shows its icon and label, 52 tall, and reports taps',
        (tester) async {
      var taps = 0;
      await pump(tester, filled: false, onPressed: () => taps++);

      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.text('Simpan Draft'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('aksi'))).height, 52);
      await tester.tap(find.byKey(const Key('aksi')));
      expect(taps, 1);
    });

    testWidgets('filled is solid green with white content', (tester) async {
      await pump(tester, filled: true, onPressed: () {});

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style!.backgroundColor!.resolve({}), AppColors.greenDark);
      expect(tester.widget<Icon>(find.byIcon(Icons.save_outlined)).color,
          Colors.white);
    });

    testWidgets('outlined is white with a green border and green content',
        (tester) async {
      await pump(tester, filled: false, onPressed: () {});

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.save_outlined)).color,
          AppColors.greenDark);
    });

    testWidgets('a disabled button is grey and ignores taps', (tester) async {
      await pump(tester, filled: true, onPressed: null);

      expect(tester.widget<Icon>(find.byIcon(Icons.save_outlined)).color,
          Colors.grey[500]);
      await tester.tap(find.byKey(const Key('aksi')), warnIfMissed: false);
    });

    testWidgets('loading swaps the icon for a spinner and keeps the label',
        (tester) async {
      var taps = 0;
      await pump(tester,
          filled: false, isLoading: true, onPressed: () => taps++);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsNothing);
      expect(find.text('Simpan Draft'), findsOneWidget);
      await tester.tap(find.byKey(const Key('aksi')), warnIfMissed: false);
      expect(taps, 0, reason: 'busy: no double taps');
    });

    testWidgets('a long label shrinks instead of overflowing', (tester) async {
      await pump(tester,
          filled: true,
          onPressed: () {},
          width: 120,
          label: 'Konfirmasi Pembayaran');

      expect(tester.takeException(), isNull);
      expect(find.text('Konfirmasi Pembayaran'), findsOneWidget);
    });
  });
}
