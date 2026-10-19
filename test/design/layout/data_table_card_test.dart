import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/data_table_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, {Widget? footer}) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          const Text('judul halaman'),
          Expanded(
            child: DataTableCard(
              header: DataTableCard.head([const Text('KOLOM')]),
              body: ListView(children: [
                for (var i = 0; i < 40; i++) Text('baris $i'),
              ]),
              footer: footer,
            ),
          ),
        ]),
      ),
    ));
  }

  testWidgets('the card takes the height left under the page header',
      (tester) async {
    await pumpCard(tester);

    final card = tester.getRect(find.byType(DataTableCard));
    expect(card.bottom, 600);
    expect(card.top, greaterThan(0));
  });

  testWidgets('only the rows scroll; head and footer stay in place',
      (tester) async {
    await pumpCard(tester, footer: const Text('paginasi'));
    final headTop = tester.getTopLeft(find.text('KOLOM')).dy;
    final footerTop = tester.getTopLeft(find.text('paginasi')).dy;

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();

    expect(find.text('baris 39'), findsOneWidget);
    expect(find.text('baris 0'), findsNothing);
    expect(tester.getTopLeft(find.text('KOLOM')).dy, headTop);
    expect(tester.getTopLeft(find.text('paginasi')).dy, footerTop);
  });

  testWidgets('the footer sits inside the card, under the rows',
      (tester) async {
    await pumpCard(tester, footer: const Text('paginasi'));

    final card = tester.getRect(find.byType(DataTableCard));
    final footer = tester.getRect(find.text('paginasi'));
    expect(footer.bottom, lessThanOrEqualTo(card.bottom));
    expect(footer.top,
        greaterThan(tester.getRect(find.byType(ListView)).bottom - 1));
  });

  testWidgets('no footer, no divider row under the list', (tester) async {
    await pumpCard(tester);

    expect(find.byType(DataTableCardFooter), findsNothing);
  });

  testWidgets('changing the page puts the rows back at the top',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late StateSetter flip;
    var page = 1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          flip = setState;
          return DataTableCard(
            pageKey: page,
            header: DataTableCard.head([const Text('KOLOM')]),
            body: ListView(children: [
              for (var i = 0; i < 40; i++) Text('baris $page-$i'),
            ]),
          );
        }),
      ),
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(find.text('baris 1-0'), findsNothing, reason: 'scrolled down');

    flip(() => page = 2);
    await tester.pump();

    expect(find.text('baris 2-0'), findsOneWidget,
        reason: 'a new page starts at its first row, not at the old offset');
  });
}
