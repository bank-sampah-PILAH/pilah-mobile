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

  testWidgets('empty compact pagination shows a zero range without controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: WebPaginationBar(
            currentPage: 0,
            totalItems: 0,
            pageSize: 10,
            itemLabel: 'nasabah',
            onPageChanged: _ignorePage,
          ),
        ),
      ),
    ));

    expect(find.text('Menampilkan 0–0 dari 0 nasabah'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('compact controls handle the first and last page',
      (tester) async {
    final selectedPages = <int>[];
    Widget pagination(int page) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: WebPaginationBar(
                currentPage: page,
                totalItems: 60,
                pageSize: 10,
                itemLabel: 'nasabah',
                onPageChanged: selectedPages.add,
              ),
            ),
          ),
        );

    await tester.pumpWidget(pagination(1));
    expect(find.bySemanticsLabel('Halaman 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Halaman 6'), findsOneWidget);
    expect(find.text('…'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_left))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Halaman berikutnya'));
    expect(selectedPages, [2]);

    await tester.pumpWidget(pagination(6));
    expect(find.bySemanticsLabel('Halaman 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Halaman 1'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Halaman sebelumnya'));
    expect(selectedPages, [2, 5]);
  });

  testWidgets('short page sets clamp the current page and hide ellipses',
      (tester) async {
    var selectedPage = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          child: WebPaginationBar(
            currentPage: 99,
            totalItems: 25,
            pageSize: 10,
            itemLabel: 'nasabah',
            onPageChanged: (page) => selectedPage = page,
          ),
        ),
      ),
    ));

    expect(find.text('Menampilkan 21–25 dari 25 nasabah'), findsOneWidget);
    for (final page in [1, 2, 3]) {
      expect(find.bySemanticsLabel('Halaman $page'), findsOneWidget);
    }
    expect(find.text('…'), findsNothing);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right))
            .onPressed,
        isNull);

    // The selected page is inert; a neighboring page remains actionable.
    await tester.tap(find.bySemanticsLabel('Halaman 2'));
    expect(selectedPage, 2);
  });
}

void _ignorePage(int _) {}
