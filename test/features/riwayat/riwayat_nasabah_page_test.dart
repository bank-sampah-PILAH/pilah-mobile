import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';

class TestRiwayatRepository extends Mock implements RiwayatRepository {}

/// Hosts the page under a cubit backed by a mocked repository — one layer
/// down from the old function-loader style, matching the pencairan tests.
Future<void> host(
  WidgetTester tester,
  TestRiwayatRepository repo, {
  List<NasabahActivity> initial = const [],
  bool hasNext = false,
}) async {
  await tester.pumpWidget(
    BlocProvider<RiwayatHistoryCubit>(
      create: (_) => RiwayatHistoryCubit(
        GetRiwayatHistoryUseCase(repo),
        GetRiwayatSetoranDetailUseCase(repo),
      )..loadHistory('member-b', reset: true),
      child: const MaterialApp(home: Scaffold(body: RiwayatNasabahPage())),
    ),
  );
}

NasabahActivity row(String id, String amount) => NasabahActivity.fromJson({
      'id': id,
      'tanggal': '2026-09-23T08:00:00+07:00',
      'tipe': 'setoran',
      'total_nilai': amount,
    });

void main() {
  setUp(() {
    registerFallbackValue(
      Left<NetworkException, RiwayatHistory>(
          NetworkException(message: 'offline')),
    );
  });

  testWidgets('loads page 1 and renders amounts with rupiah grouping',
      (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async => Right(RiwayatHistory([row('a', '12500.00')], false)),
    );
    await host(tester, repo, initial: [row('a', '12500.00')]);
    await tester.pumpAndSettle();

    verify(() => repo.history('member-b', page: 1)).called(1);
    expect(find.text('Riwayat Setoran'), findsOneWidget);
    expect(find.textContaining('12.500'), findsOneWidget);
    expect(find.text('Belum ada aktivitas'), findsNothing);
  });

  testWidgets('a failed request offers retry without an empty claim',
      (tester) async {
    final repo = TestRiwayatRepository();
    var calls = 0;
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async {
        calls++;
        return calls == 1
            ? Left(NetworkException(message: 'offline'))
            : Right(RiwayatHistory([row('a', '12500.00')], false));
      },
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada aktivitas'), findsNothing);
    expect(find.text('Coba Lagi'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12.500'), findsOneWidget);
  });

  testWidgets('an empty response has an explicit empty state', (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async => Right(const RiwayatHistory([], false)),
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada aktivitas'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
  });

  testWidgets('loads the next page without replacing earlier activities',
      (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (invocation) async {
        final page = invocation.namedArguments[#page] as int;
        return Right(RiwayatHistory(
          [row(page == 1 ? 'a' : 'b', page == 1 ? '12500.00' : '20000.00')],
          page == 1,
        ));
      },
    );
    await host(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Muat Lagi'), findsOneWidget);
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();

    verify(() => repo.history('member-b', page: 2)).called(1);
    expect(find.textContaining('12.500'), findsOneWidget);
    expect(find.textContaining('20.000'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
  });

  testWidgets('tapping a row opens the itemized detail sheet', (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async =>
          Right(RiwayatHistory([row('transaction-1', '12500.00')], false)),
    );
    when(() => repo.setoranDetail(any(), any())).thenAnswer(
      (_) async => Right(
        NasabahSetoranDetail.fromJson(const {
          'tanggal': '2026-09-23T08:00:00+07:00',
          'tipe': 'setoran',
          'total_nilai': '12500.00',
          'catatan': 'Setoran rutin',
          'saldo_setelah_transaksi': '25000.00',
          'items': [
            {
              'nama_sampah_snapshot': 'Plastik PET',
              'berat': '1.000',
              'harga_snapshot': '12500.00',
              'subtotal': '12500.00',
            },
          ],
        }),
      ),
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setoran'));
    await tester.pumpAndSettle();

    verify(() => repo.setoranDetail('member-b', 'transaction-1')).called(1);
    expect(find.text('Detail Setoran'), findsOneWidget);
    expect(find.text('Plastik PET'), findsOneWidget);
    expect(find.text('1.000 kg'), findsOneWidget);
    expect(find.text('Setoran rutin'), findsOneWidget);
  });

  testWidgets('retries the detail request after a failed sheet load',
      (tester) async {
    final repo = TestRiwayatRepository();
    var calls = 0;
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async =>
          Right(RiwayatHistory([row('transaction-1', '12500.00')], false)),
    );
    when(() => repo.setoranDetail(any(), any())).thenAnswer(
      (_) async {
        calls++;
        if (calls == 1) {
          return Left(NetworkException(message: 'offline'));
        }
        return Right(
          NasabahSetoranDetail.fromJson(const {
            'tanggal': '2026-09-23T08:00:00+07:00',
            'tipe': 'setoran',
            'total_nilai': '12500.00',
            'saldo_setelah_transaksi': '25000.00',
            'items': [
              {
                'nama_sampah_snapshot': 'Plastik PET',
                'berat': '1.000',
                'harga_snapshot': '12500.00',
                'subtotal': '12500.00',
              },
            ],
          }),
        );
      },
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setoran'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik PET'), findsNothing);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Plastik PET'), findsOneWidget);
  });

  testWidgets('the Muat ulang button re-asks page 1, not the next page',
      (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (invocation) async {
        final page = invocation.namedArguments[#page] as int;
        return Right(RiwayatHistory(
          [row('a$page', '12500.00')],
          page == 1,
        ));
      },
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Muat ulang'));
    await tester.pumpAndSettle();

    // Reset, not page+1: a refresh that appended page 2's rows would be
    // indistinguishable from paging.
    verify(() => repo.history('member-b', page: 1)).called(2);
    verifyNever(() => repo.history(any(), page: 2));
    expect(find.textContaining('12.500'), findsOneWidget);
  });

  testWidgets('pull-to-refresh re-asks page 1 too', (tester) async {
    final repo = TestRiwayatRepository();
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (invocation) async =>
          Right(RiwayatHistory([row('a', '12500.00')], false)),
    );
    await host(tester, repo);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();

    verify(() => repo.history('member-b', page: 1)).called(2);
    verifyNever(() => repo.history(any(), page: 2));
  });
}
