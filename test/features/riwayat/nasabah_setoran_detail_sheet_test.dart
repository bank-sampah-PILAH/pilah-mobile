import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/presentation/widgets/nasabah_setoran_detail_sheet.dart';

NasabahSetoranDetail _detail() => NasabahSetoranDetail(
      date: DateTime(2026, 10, 10, 18, 46),
      type: 'setoran',
      amount: '3000.00',
      note: 'Plastik bersih',
      balanceAfter: '490500.00',
      items: const [],
    );

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<NasabahSetoranDetail> Function() load,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NasabahSetoranDetailSheet(loadDetail: load)),
    ));
    await tester.pump();
  }

  testWidgets('shows a spinner while the detail loads', (tester) async {
    final never = Future<NasabahSetoranDetail>.delayed(
      const Duration(days: 1),
      _detail,
    );
    await open(tester, () => never);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(days: 1));
  });

  testWidgets('shows the rows of the setoran once it has loaded',
      (tester) async {
    await open(tester, () async => _detail());

    expect(find.text('Detail Setoran'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Plastik bersih'), findsOneWidget);
  });

  testWidgets('a network failure shows its own message', (tester) async {
    await open(
      tester,
      () async => throw NetworkException(message: 'Tidak ada koneksi internet'),
    );

    expect(find.textContaining('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.text('Rincian setoran gagal dimuat.'), findsNothing);
  });

  testWidgets('an unexpected error reads as a plain failure and can be retried',
      (tester) async {
    var calls = 0;
    await open(tester, () async {
      calls++;
      if (calls == 1) throw StateError('boom');
      return _detail();
    });

    expect(find.text('Rincian setoran gagal dimuat.'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.text('Rincian setoran gagal dimuat.'), findsNothing);
    expect(find.text('Plastik bersih'), findsOneWidget);
  });
}
