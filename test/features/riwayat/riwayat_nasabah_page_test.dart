import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';

NasabahHistory page(List<Map<String, dynamic>> rows, {String? next}) =>
    NasabahHistory(rows.map(NasabahActivity.fromJson).toList(), next != null);

Map<String, dynamic> activity(String id, String amount) => {
      'id': id,
      'tanggal': '2026-09-23T08:00:00+07:00',
      'tipe': 'setoran',
      'total_nilai': amount,
    };

NasabahSetoranDetail setoranDetail() => NasabahSetoranDetail(
      date: DateTime.parse('2026-09-23T08:00:00+07:00'),
      type: 'setoran',
      amount: '12500.00',
      note: 'Setoran rutin',
      balanceAfter: '25000.00',
      items: const [
        NasabahSetoranItem(
          name: 'Plastik PET',
          weight: '1.000',
          price: '12500.00',
          subtotal: '12500.00',
        ),
      ],
    );

Widget host(
  HistoryLoader loader, {
  Future<NasabahSetoranDetail> Function(String)? loadDetail,
}) =>
    MaterialApp(
      home: Scaffold(
        body: RiwayatNasabahPage(
          loadPage: loader,
          loadDetail: loadDetail ?? (_) async => setoranDetail(),
        ),
      ),
    );

void main() {
  testWidgets('failed next page preserves rows and retries the same page',
      (tester) async {
    final requests = <int>[];
    var fail = true;
    await tester.pumpWidget(host((number) async {
      requests.add(number);
      if (number == 2 && fail) throw Exception('offline');
      return number == 1
          ? page([activity('a', '12500.00')], next: '?page=2')
          : page([activity('b', '20000.00')]);
    }));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12.500'), findsOneWidget);
    expect(find.text('Belum ada aktivitas'), findsNothing);
    fail = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(requests, [1, 2, 2]);
    expect(find.textContaining('20.000'), findsOneWidget);
  });

  testWidgets('refresh replaces prior pages and keeps decimal precision',
      (tester) async {
    var refreshed = false;
    await tester.pumpWidget(host((_) async => page([
          activity(refreshed ? 'b' : 'a',
              refreshed ? '999999999999.99' : '12500.00'),
        ])));
    await tester.pumpAndSettle();
    refreshed = true;
    expect(find.byTooltip('Muat ulang'), findsOneWidget);
    await tester.tap(find.byTooltip('Muat ulang'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12.500'), findsNothing);
    expect(find.text('+ Rp 999.999.999.999,99'), findsOneWidget);
  });

  testWidgets('a response arriving after disposal does not update the page',
      (tester) async {
    final pending = Completer<NasabahHistory>();
    await tester.pumpWidget(host((_) => pending.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(page([activity('a', '12500.00')]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('requests the first page and shows loading until it resolves', (
    tester,
  ) async {
    final pending = Completer<NasabahHistory>();
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
    expect(find.text('Riwayat Setoran'), findsOneWidget);
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

  testWidgets('tapping a setoran opens its itemized detail sheet', (
    tester,
  ) async {
    String? requestedId;
    await tester.pumpWidget(
      host(
        (_) async => page([activity('transaction-1', '12500.00')]),
        loadDetail: (id) async {
          requestedId = id;
          return setoranDetail();
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setoran'));
    await tester.pumpAndSettle();

    expect(requestedId, 'transaction-1');
    expect(find.text('Detail Setoran'), findsOneWidget);
    expect(find.text('Plastik PET'), findsOneWidget);
    expect(find.text('1.000 kg'), findsOneWidget);
    expect(find.text('Rp 12.500'), findsNWidgets(3));
    expect(find.text('Setoran rutin'), findsOneWidget);
  });

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

  testWidgets('shows the API message when the history cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(host((_) async {
      throw const NasabahApiException('Sesi berakhir. Silakan masuk kembali.');
    }));
    await tester.pumpAndSettle();

    expect(find.text('Sesi berakhir. Silakan masuk kembali.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('pulling down reloads the first page', (tester) async {
    final requests = <int>[];
    await tester.pumpWidget(host((number) async {
      requests.add(number);
      return page([activity('a', '12500.00')]);
    }));
    await tester.pumpAndSettle();

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pumpAndSettle();

    expect(requests, [1, 1]);
  });

  group('setoran detail sheet', () {
    testWidgets(
        'explains an API failure and requests the detail again on retry', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(host(
        (_) async => page([activity('transaction-1', '12500.00')]),
        loadDetail: (_) async {
          if (++calls == 1) {
            throw const NasabahApiException('Data tidak ditemukan.');
          }
          return setoranDetail();
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setoran'));
      await tester.pumpAndSettle();
      expect(find.text('Data tidak ditemukan.'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Data tidak ditemukan.'), findsNothing);
      expect(find.text('Plastik PET'), findsOneWidget);
    });

    testWidgets('falls back to a generic message for unexpected failures', (
      tester,
    ) async {
      await tester.pumpWidget(host(
        (_) async => page([activity('transaction-1', '12500.00')]),
        loadDetail: (_) async => throw Exception('boom'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setoran'));
      await tester.pumpAndSettle();

      expect(find.text('Rincian setoran gagal dimuat.'), findsOneWidget);
    });
  });
}
