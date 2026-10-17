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
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('shows a back button that goes back when asked to',
      (tester) async {
    await open(
      tester,
      const NasabahPageAppBar(title: 'Detail Bank Sampah', showBack: true),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
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
