import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

Future<void> _show(WidgetTester tester, Widget dialog) async {
  // A fresh tree, so a second call in a test does not keep the first dialog.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => dialog,
          ),
          child: const Text('buka'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('buka'));
  // Not pumpAndSettle: a loading button spins for ever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The colour a button is painted with, which is what a user sees.
Color? _fill(WidgetTester tester, Finder button) => tester
    .widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    )
    .color;

void main() {
  group('AppDialog', () {
    testWidgets('shows its title, message and both answers', (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Simpan perubahan?',
          message: 'Saldo akan dihitung ulang.',
          confirmLabel: 'Simpan',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.text('Simpan perubahan?'), findsOneWidget);
      expect(find.text('Saldo akan dihitung ulang.'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('the title is 18 semibold', (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Simpan perubahan?',
          confirmLabel: 'Simpan',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      final style = tester
          .renderObject<RenderParagraph>(find.text('Simpan perubahan?'))
          .text
          .style;
      expect(style?.fontSize, 18);
      expect(style?.fontWeight, FontWeight.w600);
    });

    testWidgets('the cancel label can be changed', (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Hapus?',
          confirmLabel: 'Hapus',
          cancelLabel: 'Kembali',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Batal'), findsNothing);
    });

    testWidgets('reports each answer', (tester) async {
      var confirmed = 0;
      var cancelled = 0;
      await _show(
        tester,
        AppDialog(
          title: 'Simpan?',
          confirmLabel: 'Simpan',
          onConfirm: () => confirmed++,
          onCancel: () => cancelled++,
        ),
      );

      await tester.tap(find.text('Simpan'));
      await tester.tap(find.text('Batal'));

      expect([confirmed, cancelled], [1, 1]);
    });

    testWidgets('confirm is green, and red when the action is destructive',
        (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Simpan?',
          confirmLabel: 'Simpan',
          onConfirm: () {},
          onCancel: () {},
        ),
      );
      expect(_fill(tester, find.widgetWithText(ElevatedButton, 'Simpan')),
          AppColors.greenDark);

      await _show(
        tester,
        AppDialog(
          title: 'Hapus?',
          confirmLabel: 'Hapus',
          destructive: true,
          onConfirm: () {},
          onCancel: () {},
        ),
      );
      expect(_fill(tester, find.widgetWithText(ElevatedButton, 'Hapus')),
          AppColors.danger);
    });

    testWidgets(
        'shows custom content, such as a text field, in place of a message',
        (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Ajukan Banding',
          content: const TextField(key: Key('alasan')),
          confirmLabel: 'Kirim',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.byKey(const Key('alasan')), findsOneWidget);
    });

    testWidgets('a loading confirm button ignores taps', (tester) async {
      var confirmed = 0;
      await _show(
        tester,
        AppDialog(
          title: 'Simpan?',
          confirmLabel: 'Simpan',
          isLoading: true,
          onConfirm: () => confirmed++,
          onCancel: () {},
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(confirmed, 0);
    });

    testWidgets('has the 16 radius of a dialog', (tester) async {
      await _show(
        tester,
        AppDialog(
          title: 'Simpan?',
          confirmLabel: 'Simpan',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        surface.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    });
  });

  group('AppIconDialog', () {
    Widget dialog({
      AppDialogTone tone = AppDialogTone.positive,
      bool destructive = false,
      bool isLoading = false,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
    }) =>
        AppIconDialog(
          icon: Icons.check_box,
          tone: tone,
          title: 'Aktifkan Nasabah?',
          message: const [
            TextSpan(text: 'Yakin ingin mengaktifkan '),
            TextSpan(
              text: 'Budi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '?'),
          ],
          confirmLabel: 'Ya, Aktifkan',
          destructive: destructive,
          isLoading: isLoading,
          onConfirm: onConfirm ?? () {},
          onCancel: onCancel ?? () {},
        );

    testWidgets('shows the icon, the title and a message with bold names',
        (tester) async {
      await _show(tester, dialog());

      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.text('Aktifkan Nasabah?'), findsOneWidget);
      expect(
        find.textContaining('Yakin ingin mengaktifkan Budi?',
            findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the icon sits in a tinted circle that follows the tone',
        (tester) async {
      BoxDecoration circle() => tester
          .widget<Container>(find
              .ancestor(
                of: find.byIcon(Icons.check_box),
                matching: find.byType(Container),
              )
              .first)
          .decoration! as BoxDecoration;

      await _show(tester, dialog());
      expect(circle().color, AppColors.greenLight);
      expect(circle().shape, BoxShape.circle);
      expect(tester.widget<Icon>(find.byIcon(Icons.check_box)).color,
          AppColors.greenDark);

      await _show(tester, dialog(tone: AppDialogTone.warning));
      expect(circle().color, AppColors.warningLight);
      expect(tester.widget<Icon>(find.byIcon(Icons.check_box)).color,
          AppColors.warning);
    });

    testWidgets('the two answers have the same width, side by side',
        (tester) async {
      await _show(tester, dialog());

      final cancel =
          tester.getRect(find.widgetWithText(OutlinedButton, 'Batal'));
      final confirm =
          tester.getRect(find.widgetWithText(ElevatedButton, 'Ya, Aktifkan'));
      expect(cancel.right, lessThan(confirm.left));
      expect(cancel.width, confirm.width);
      expect(cancel.top, confirm.top);
    });

    testWidgets('confirm is red when the action is destructive',
        (tester) async {
      await _show(tester, dialog(destructive: true));

      expect(
        _fill(tester, find.widgetWithText(ElevatedButton, 'Ya, Aktifkan')),
        AppColors.danger,
      );
    });

    testWidgets('while loading, neither answer can be tapped', (tester) async {
      var confirmed = 0;
      var cancelled = 0;
      await _show(
        tester,
        dialog(
          isLoading: true,
          onConfirm: () => confirmed++,
          onCancel: () => cancelled++,
        ),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.tap(find.text('Batal'), warnIfMissed: false);

      expect([confirmed, cancelled], [0, 0]);
    });

    testWidgets('has the 16 radius of a dialog, like every other',
        (tester) async {
      await _show(tester, dialog());

      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        surface.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    });
  });
}
