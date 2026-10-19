import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';

void main() {
  testWidgets('shows the current range and nearby page numbers',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WebPaginationBar(
          currentPage: 7,
          totalItems: 5062,
          pageSize: 10,
          itemLabel: 'transaksi',
          onPageChanged: _ignorePage,
        ),
      ),
    ));

    expect(find.text('Menampilkan 61–70 dari 5.062 transaksi'), findsOneWidget);
    for (final page in [1, 6, 7, 8, 507]) {
      expect(find.bySemanticsLabel('Halaman $page'), findsOneWidget);
    }
    expect(find.text('…'), findsNWidgets(2));
  });

  testWidgets('selects another page', (tester) async {
    var selectedPage = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WebPaginationBar(
          currentPage: 1,
          totalItems: 30,
          pageSize: 10,
          itemLabel: 'nasabah',
          onPageChanged: (page) => selectedPage = page,
        ),
      ),
    ));

    await tester.tap(find.bySemanticsLabel('Halaman 2'));

    expect(selectedPage, 2);
  });
}

void _ignorePage(int _) {}
