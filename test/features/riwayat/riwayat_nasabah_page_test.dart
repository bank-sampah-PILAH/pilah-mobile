import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';

Map<String, dynamic> page(List<Map<String, dynamic>> rows, {String? next}) => {
  'count': rows.length,
  'next': next,
  'previous': null,
  'results': rows,
};

Map<String, dynamic> activity(String id, String amount) => {
  'id': id,
  'tanggal': '2026-09-23T08:00:00+07:00',
  'tipe': 'setoran',
  'total_nilai': amount,
};

Widget host(HistoryLoader loader) => MaterialApp(
  home: Scaffold(body: RiwayatNasabahPage(loadPage: loader)),
);

void main() {
  testWidgets('requests the first page and shows loading until it resolves', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    final requests = <int>[];
    await tester.pumpWidget(
      host((number) {
        requests.add(number);
        return pending.future;
      }),
    );
    expect(requests, [1]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(page([]));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an empty response has an explicit empty state', (tester) async {
    await tester.pumpWidget(host((_) async => page([])));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Belum ada aktivitas'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
  });

  testWidgets(
    'renders the API decimal amount as rupiah and the activity type',
    (tester) async {
      await tester.pumpWidget(
        host((_) async => page([activity('a', '12500.00')])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Setoran'), findsOneWidget);
      expect(find.textContaining('12.500'), findsOneWidget);
      expect(find.text('Belum ada aktivitas'), findsNothing);
    },
  );

  testWidgets(
    'a failed request offers retry without claiming the list is empty',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host((_) async {
          if (++calls == 1) throw Exception('offline');
          return page([activity('a', '12500.00')]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada aktivitas'), findsNothing);
      expect(find.text('Coba Lagi'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('12.500'), findsOneWidget);
    },
  );

  testWidgets('loads the next page without replacing earlier activities', (
    tester,
  ) async {
    final requests = <int>[];
    await tester.pumpWidget(
      host((number) async {
        requests.add(number);
        return number == 1
            ? page([activity('a', '12500.00')], next: '?page=2')
            : page([activity('b', '20000.00')]);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Muat Lagi'), findsOneWidget);
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(requests, [1, 2]);
    expect(find.textContaining('12.500'), findsOneWidget);
    expect(find.textContaining('20.000'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
  });
}
