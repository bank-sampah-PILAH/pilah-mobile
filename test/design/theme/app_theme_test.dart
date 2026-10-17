import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

/// The colour a rendered label ends up with, which is what a user sees.
Color? _labelColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

void main() {
  group('typography', () {
    testWidgets('plain text renders in Poppins, not the platform default',
        (tester) async {
      await tester.pumpWidget(_app(const Text('Belum ada jadwal')));

      final style = tester
          .renderObject<RenderParagraph>(find.text('Belum ada jadwal'))
          .text
          .style;
      expect(style?.fontFamily, contains('Poppins'));
    });
  });

  group('typography weights', () {
    testWidgets('bold plain text is real Poppins, not a lighter face',
        (tester) async {
      await tester.pumpWidget(_app(
        const Text(
          'Oktober 2026',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ));

      final style = tester
          .renderObject<RenderParagraph>(find.text('Oktober 2026'))
          .text
          .style;
      expect(style?.fontFamily, 'Poppins');
      expect(style?.fontWeight, FontWeight.w700);
    });
  });

  group('buttons', () {
    testWidgets('a plain TextButton uses the app green, not the seed colour',
        (tester) async {
      await tester.pumpWidget(
        _app(TextButton(onPressed: () {}, child: const Text('Semua'))),
      );

      expect(_labelColor(tester, 'Semua'), AppColors.greenDark);
    });

    Material surfaceOf(WidgetTester tester, Type button) => tester.widget(
          find
              .descendant(
                of: find.byType(button),
                matching: find.byType(Material),
              )
              .first,
        );

    for (final entry in <String, Widget Function()>{
      'ElevatedButton': () =>
          ElevatedButton(onPressed: () {}, child: const Text('Simpan')),
      'FilledButton': () =>
          FilledButton(onPressed: () {}, child: const Text('Simpan')),
    }.entries) {
      testWidgets(
          'a plain ${entry.key} is a flat green button with a white label',
          (tester) async {
        await tester.pumpWidget(_app(entry.value()));

        final surface = surfaceOf(
          tester,
          entry.key == 'ElevatedButton' ? ElevatedButton : FilledButton,
        );
        expect(surface.color, AppColors.greenDark);
        expect(surface.elevation, 0);
        expect(
          surface.shape,
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
        expect(_labelColor(tester, 'Simpan'), Colors.white);
      });
    }

    testWidgets('a plain OutlinedButton has a green border and label',
        (tester) async {
      await tester.pumpWidget(
        _app(OutlinedButton(onPressed: () {}, child: const Text('Tambah'))),
      );

      final shape =
          surfaceOf(tester, OutlinedButton).shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.greenDark);
      expect(shape.borderRadius, BorderRadius.circular(12));
      expect(_labelColor(tester, 'Tambah'), AppColors.greenDark);
    });

    for (final entry in <String, Widget Function()>{
      'ElevatedButton': () =>
          ElevatedButton(onPressed: () {}, child: const Text('Simpan')),
      'FilledButton': () =>
          FilledButton(onPressed: () {}, child: const Text('Simpan')),
      'OutlinedButton': () =>
          OutlinedButton(onPressed: () {}, child: const Text('Simpan')),
    }.entries) {
      testWidgets(
          'a plain ${entry.key} label is 14 semibold, small enough for two '
          'buttons side by side', (tester) async {
        await tester.pumpWidget(_app(entry.value()));

        final style = tester
            .renderObject<RenderParagraph>(find.text('Simpan'))
            .text
            .style;
        expect(style?.fontSize, 14);
        expect(style?.fontWeight, FontWeight.w600);
      });
    }

    for (final (name, type, build) in <(String, Type, Widget Function())>[
      (
        'ElevatedButton',
        ElevatedButton,
        () => ElevatedButton(onPressed: () {}, child: const Text('Simpan')),
      ),
      (
        'FilledButton',
        FilledButton,
        () => FilledButton(onPressed: () {}, child: const Text('Simpan')),
      ),
      (
        'OutlinedButton',
        OutlinedButton,
        () => OutlinedButton(onPressed: () {}, child: const Text('Simpan')),
      ),
    ]) {
      testWidgets('a plain $name is 48 high, like an AppButton',
          (tester) async {
        await tester.pumpWidget(_app(build()));

        // The painted surface, not the 48 dp tap target around it.
        final surface = find
            .descendant(of: find.byType(type), matching: find.byType(Material))
            .first;
        expect(tester.getSize(surface).height, 48);
      });
    }

    testWidgets('a disabled filled button is grey, not a faded green',
        (tester) async {
      await tester.pumpWidget(
        _app(const ElevatedButton(onPressed: null, child: Text('Simpan'))),
      );

      expect(surfaceOf(tester, ElevatedButton).color, AppColors.border);
    });
  });

  group('dialogs', () {
    testWidgets(
        'a stock AlertDialog is white and rounded, with no tinted surface',
        (tester) async {
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      final context = tester.element(find.byType(Scaffold));
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Batalkan jadwal?'),
          actions: [TextButton(onPressed: () {}, child: const Text('Kembali'))],
        ),
      );
      await tester.pumpAndSettle();

      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color, Colors.white);
      expect(surface.surfaceTintColor, Colors.transparent);
      expect(
        surface.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    });
  });

  group('scaffold', () {
    testWidgets('a page with no background of its own is white, not tinted',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SizedBox.expand()),
      ));

      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).scaffoldBackgroundColor, Colors.white);
    });
  });

  group('cards', () {
    testWidgets(
        'a stock Card is white and flat with a thin border, no tint or margin',
        (tester) async {
      await tester.pumpWidget(
        _app(const Card(child: SizedBox(width: 100, height: 40))),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final theme = Theme.of(tester.element(find.byType(Card))).cardTheme;
      expect(card.color ?? theme.color, Colors.white);
      expect(theme.surfaceTintColor, Colors.transparent);
      expect(theme.elevation, 0);
      expect(theme.margin, EdgeInsets.zero);
      expect(
        theme.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      );
    });
  });

  group('app bar', () {
    testWidgets('a plain AppBar is white with a semibold Poppins title',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(appBar: AppBar(title: const Text('Edit Pencairan'))),
      ));

      final bar = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(bar.color, Colors.white);
      expect(bar.surfaceTintColor, Colors.transparent);
      final title = tester
          .renderObject<RenderParagraph>(find.text('Edit Pencairan'))
          .text
          .style;
      expect(title?.fontWeight, FontWeight.w600);
    });
  });

  group('bottom sheets', () {
    testWidgets('a stock modal sheet is white with rounded top corners',
        (tester) async {
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      final context = tester.element(find.byType(Scaffold));
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => const SizedBox(height: 120, child: Text('Pilih akun')),
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      final theme = Theme.of(context).bottomSheetTheme;
      expect(sheet.backgroundColor ?? theme.backgroundColor, Colors.white);
      expect(theme.surfaceTintColor, Colors.transparent);
      expect(
        theme.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      );
    });
  });
}
