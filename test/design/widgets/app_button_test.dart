import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

Widget _host(Widget child, {double width = 320}) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Color? _labelColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

/// The fill the button is painted with, which is what a user sees.
Color? _fill(WidgetTester tester, Type button) => tester
    .widget<Material>(
      find
          .descendant(of: find.byType(button), matching: find.byType(Material))
          .first,
    )
    .color;

OutlinedBorder? _shape(WidgetTester tester, Type button) => tester
    .widget<Material>(
      find
          .descendant(of: find.byType(button), matching: find.byType(Material))
          .first,
    )
    .shape as OutlinedBorder?;

void main() {
  group('AppButton variants', () {
    testWidgets('primary is a green filled button with a white label',
        (tester) async {
      await tester.pumpWidget(
          _host(AppButton(label: 'Simpan', onPressed: () {})));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.greenDark);
      expect(_labelColor(tester, 'Simpan'), Colors.white);
    });

    testWidgets('destructive is a red filled button with a white label',
        (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Ya, Keluar',
        variant: AppButtonVariant.destructive,
        onPressed: () {},
      )));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.danger);
      expect(_labelColor(tester, 'Ya, Keluar'), Colors.white);
    });

    testWidgets('outlined has a green border and a green label',
        (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Tambah Nasabah',
        variant: AppButtonVariant.outlined,
        onPressed: () {},
      )));

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(_labelColor(tester, 'Tambah Nasabah'), AppColors.greenDark);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.greenDark);
    });

    testWidgets('neutral is an outlined button in the grey of a cancel action',
        (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Kembali',
        variant: AppButtonVariant.neutral,
        onPressed: () {},
      )));

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(_labelColor(tester, 'Kembali'), AppColors.inkSoft);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.border);
    });

    testWidgets('every variant uses the 12 radius of the design scale',
        (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
            _host(AppButton(label: 'Aksi', variant: variant, onPressed: () {})));
        final type = variant == AppButtonVariant.outlined ||
                variant == AppButtonVariant.neutral
            ? OutlinedButton
            : ElevatedButton;

        expect(
          _shape(tester, type)?.borderRadiusResolve(),
          BorderRadius.circular(12),
          reason: '$variant',
        );
      }
    });
  });

  group('AppButton layout', () {
    testWidgets('fills the width it is given and is 48 high', (tester) async {
      await tester.pumpWidget(
          _host(AppButton(label: 'Simpan', onPressed: () {})));

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.width, 320);
      expect(size.height, 48);
    });

    testWidgets('hugs its label when expand is false', (tester) async {
      await tester.pumpWidget(_host(
        Center(
          child: AppButton(label: 'Simpan', expand: false, onPressed: () {}),
        ),
      ));

      expect(tester.getSize(find.byType(ElevatedButton)).width, lessThan(320));
      expect(tester.getSize(find.byType(ElevatedButton)).height, 48);
    });

    testWidgets('puts the icon before the label', (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Transaksi Baru',
        icon: Icons.add,
        onPressed: () {},
      )));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        lessThan(tester.getCenter(find.text('Transaksi Baru')).dx),
      );
    });
  });

  group('AppButton behaviour', () {
    testWidgets('reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
          _host(AppButton(label: 'Simpan', onPressed: () => taps++)));

      await tester.tap(find.text('Simpan'));

      expect(taps, 1);
    });

    testWidgets('is greyed out and ignores taps without a callback',
        (tester) async {
      await tester.pumpWidget(
          _host(const AppButton(label: 'Simpan', onPressed: null)));

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);
      expect(_fill(tester, ElevatedButton), AppColors.border);
    });

    testWidgets('shows a spinner instead of the label while loading and does '
        'not fire twice', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(AppButton(
        label: 'Simpan',
        isLoading: true,
        onPressed: () => taps++,
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('keeps its label for screen readers while loading',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(AppButton(
        label: 'Simpan',
        isLoading: true,
        onPressed: () {},
      )));

      expect(
        tester.getSemantics(find.byType(ElevatedButton)),
        matchesSemantics(
          label: 'Simpan',
          isButton: true,
          hasEnabledState: true,
          hasTapAction: false,
          hasFocusAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('announces itself as a button with its label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
          _host(AppButton(label: 'Simpan', onPressed: () {})));

      expect(
        tester.getSemantics(find.byType(ElevatedButton)),
        matchesSemantics(
          label: 'Simpan',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });
  });
}

extension on OutlinedBorder? {
  BorderRadius? borderRadiusResolve() {
    final shape = this;
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius.resolve(TextDirection.ltr);
    }
    return null;
  }
}
