import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';

void main() {
  Widget host(NasabahPageAppBar bar) => MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => Scaffold(appBar: bar, body: const SizedBox()),
            )),
            child: const Text('buka'),
          ),
        ),
      );

  Future<void> open(WidgetTester tester, NasabahPageAppBar bar) async {
    await tester.pumpWidget(host(bar));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows its title and no back button by default', (tester) async {
    await open(tester, const NasabahPageAppBar(title: 'Tabungan Saya'));

    expect(find.text('Tabungan Saya'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('shows a subtitle under the title when it has one',
      (tester) async {
    await open(
      tester,
      const NasabahPageAppBar(
        title: 'Riwayat Harga',
        subtitle: 'Botol Plastik',
        showBack: true,
      ),
    );

    expect(find.text('Riwayat Harga'), findsOneWidget);
    expect(find.text('Botol Plastik'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Botol Plastik')).dy,
      greaterThan(tester.getTopLeft(find.text('Riwayat Harga')).dy),
    );
  });

  testWidgets('shows a back button that goes back when asked to',
      (tester) async {
    await open(
      tester,
      const NasabahPageAppBar(title: 'Detail Bank Sampah', showBack: true),
    );

    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Detail Bank Sampah'), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });

  testWidgets('keeps its actions at the right', (tester) async {
    await open(
      tester,
      NasabahPageAppBar(
        title: 'Pratinjau',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Unduh',
            icon: const Icon(Icons.download_rounded),
            onPressed: () {},
          ),
        ],
      ),
    );

    expect(
      tester.getCenter(find.byIcon(Icons.download_rounded)).dx,
      greaterThan(tester.getCenter(find.text('Pratinjau')).dx),
    );
  });

  testWidgets('a long title ends in an ellipsis instead of overflowing',
      (tester) async {
    await open(
      tester,
      const NasabahPageAppBar(
        title: 'laporan-riwayat-aktivitas-pilah-2026-10-17-sangat-panjang.pdf',
        showBack: true,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
