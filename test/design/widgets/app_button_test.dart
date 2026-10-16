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
          .descendant(
            of: find.byType(button),
            matching: find.byType(Material),
          )
          .first,
    )
    .shape as OutlinedBorder?;

void main() {
  group('AppButton variants', () {
    testWidgets('primary is a green filled button with a white label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppButton(label: 'Simpan', onPressed: () {})),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.greenDark);
      expect(_labelColor(tester, 'Simpan'), Colors.white);
    });

    testWidgets('destructive is a red filled button with a white label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Ya, Keluar',
            variant: AppButtonVariant.destructive,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.danger);
      expect(_labelColor(tester, 'Ya, Keluar'), Colors.white);
    });

    testWidgets('outlined has a green border and a green label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Tambah Nasabah',
            variant: AppButtonVariant.outlined,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(_labelColor(tester, 'Tambah Nasabah'), AppColors.greenDark);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.greenDark);
    });

    testWidgets(
      'neutral is an outlined button in the grey of a cancel action',
      (tester) async {
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Kembali',
              variant: AppButtonVariant.neutral,
              onPressed: () {},
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(_labelColor(tester, 'Kembali'), AppColors.inkSoft);
        expect(_shape(tester, OutlinedButton)?.side.color, AppColors.border);
      },
    );

    testWidgets('destructive outlined has a red border and a red label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Tolak',
            variant: AppButtonVariant.destructiveOutlined,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(_labelColor(tester, 'Tolak'), AppColors.danger);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.danger);
    });

    testWidgets('neutral keeps a white fill so it reads on a tinted page', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Kembali',
            variant: AppButtonVariant.neutral,
            onPressed: () {},
          ),
        ),
      );

      expect(_fill(tester, OutlinedButton), Colors.white);
    });

    testWidgets('every variant uses the 12 radius of the design scale', (
      tester,
    ) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _host(AppButton(label: 'Aksi', variant: variant, onPressed: () {})),
        );
        // A text link has no surface to round.
        if (variant == AppButtonVariant.text) continue;
        final type = switch (variant) {
          AppButtonVariant.primary ||
          AppButtonVariant.destructive ||
          AppButtonVariant.tonal =>
            ElevatedButton,
          _ => OutlinedButton,
        };

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
        _host(AppButton(label: 'Simpan', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.width, 320);
      expect(size.height, 48);
    });

    testWidgets('hugs its label when expand is false', (tester) async {
      await tester.pumpWidget(
        _host(
          Center(
            child: AppButton(label: 'Simpan', expand: false, onPressed: () {}),
          ),
        ),
      );

      expect(tester.getSize(find.byType(ElevatedButton)).width, lessThan(320));
      expect(tester.getSize(find.byType(ElevatedButton)).height, 48);
    });

    testWidgets('puts the icon before the label', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Transaksi Baru', icon: Icons.add, onPressed: () {}),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        lessThan(tester.getCenter(find.text('Transaksi Baru')).dx),
      );
    });
  });

  testWidgets(
      'shows a custom leading widget, such as a brand logo, instead '
      'of an icon', (tester) async {
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Masuk dengan Google',
          variant: AppButtonVariant.neutral,
          leading: const SizedBox(key: Key('logo'), width: 24, height: 24),
          onPressed: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('logo')), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('logo'))).dx,
      lessThan(tester.getCenter(find.text('Masuk dengan Google')).dx),
    );
  });

  testWidgets('has no icon unless one is given', (tester) async {
    await tester.pumpWidget(
      _host(AppButton(label: 'Simpan', onPressed: () {})),
    );

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('puts a trailing icon after the label', (tester) async {
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Simpan Profil & Lanjut',
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(
      tester.getCenter(find.byIcon(Icons.arrow_forward)).dx,
      greaterThan(tester.getCenter(find.text('Simpan Profil & Lanjut')).dx),
    );
  });

  testWidgets(
      'a button that fills its width keeps only 12 of side padding, '
      'so two side by side fit a long label', (tester) async {
    EdgeInsetsGeometry? padding(Finder finder) =>
        tester.widget<ElevatedButton>(finder).style?.padding?.resolve({});

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppButton(label: 'Ya, Nonaktifkan', onPressed: () {}),
            AppButton(label: 'Simpan', expand: false, onPressed: () {}),
          ],
        ),
      ),
    );

    expect(
      padding(find.widgetWithText(ElevatedButton, 'Ya, Nonaktifkan')),
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
    expect(
      padding(find.widgetWithText(ElevatedButton, 'Simpan')),
      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  });

  group('AppButton tonal', () {
    testWidgets('is a soft green button with a green label', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Tandai Selesai',
            variant: AppButtonVariant.tonal,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.greenLight);
      expect(_labelColor(tester, 'Tandai Selesai'), AppColors.greenDark);
    });
  });

  group('AppButton warning', () {
    testWidgets('filled is amber with a white label', (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Ya, Lanjutkan',
        variant: AppButtonVariant.warning,
        onPressed: () {},
      )));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_fill(tester, ElevatedButton), AppColors.warning);
      expect(_labelColor(tester, 'Ya, Lanjutkan'), Colors.white);
    });

    testWidgets('outlined has an amber border and an amber label',
        (tester) async {
      await tester.pumpWidget(_host(AppButton(
        label: 'Samakan dengan data akun',
        variant: AppButtonVariant.warningOutlined,
        onPressed: () {},
      )));

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(
          _labelColor(tester, 'Samakan dengan data akun'), AppColors.warning);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.warning);
    });
  });

  group('AppButton compact', () {
    testWidgets('is 40 high where the regular button is 48', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              AppButton(label: 'Terapkan', onPressed: () {}),
              AppButton(
                label: 'Setujui',
                size: AppButtonSize.compact,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSize(find.widgetWithText(ElevatedButton, 'Terapkan')).height,
        48,
      );
      expect(
        tester.getSize(find.widgetWithText(ElevatedButton, 'Setujui')).height,
        40,
      );
    });

    testWidgets('still fills the width it is given', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Setujui',
            size: AppButtonSize.compact,
            onPressed: () {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(ElevatedButton)).width, 320);
    });

    testWidgets('keeps the look of its variant', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Tolak',
            variant: AppButtonVariant.destructiveOutlined,
            size: AppButtonSize.compact,
            onPressed: () {},
          ),
        ),
      );

      expect(_labelColor(tester, 'Tolak'), AppColors.danger);
      expect(_shape(tester, OutlinedButton)?.side.color, AppColors.danger);
    });
  });

  group('AppButton text', () {
    testWidgets('is a bare green link with no padding around its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Detail Bank Sampah',
              variant: AppButtonVariant.text,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(_labelColor(tester, 'Detail Bank Sampah'), AppColors.greenDark);
      final button = tester.getRect(find.byType(TextButton));
      final label = tester.getRect(find.text('Detail Bank Sampah'));
      expect(button.left, label.left);
      expect(button.width, label.width);
    });

    testWidgets('never fills the row, even though expand defaults to true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Detail',
              variant: AppButtonVariant.text,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(TextButton)).width, lessThan(320));
    });

    testWidgets('puts the icon before the label', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Lihat Status',
            variant: AppButtonVariant.text,
            icon: Icons.fact_check_outlined,
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getCenter(find.byIcon(Icons.fact_check_outlined)).dx,
        lessThan(tester.getCenter(find.text('Lihat Status')).dx),
      );
    });
  });

  group('AppButton behaviour', () {
    testWidgets('reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppButton(label: 'Simpan', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Simpan'));

      expect(taps, 1);
    });

    testWidgets('is greyed out and ignores taps without a callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppButton(label: 'Simpan', onPressed: null)),
      );

      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
        isFalse,
      );
      expect(_fill(tester, ElevatedButton), AppColors.border);
    });

    testWidgets(
        'shows a spinner instead of the label while loading and does '
        'not fire twice', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Simpan', isLoading: true, onPressed: () => taps++),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('keeps its label for screen readers while loading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppButton(label: 'Simpan', isLoading: true, onPressed: () {})),
      );

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

    testWidgets('announces itself as a button with its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppButton(label: 'Simpan', onPressed: () {})),
      );

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
