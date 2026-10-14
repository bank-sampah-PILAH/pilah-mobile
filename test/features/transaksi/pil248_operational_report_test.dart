import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';

class _Network extends Mock implements NetworkService {}

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

const _totals = <String, dynamic>{
  'jumlah_transaksi': 25,
  'total_berat': '12.50',
  'total_setoran': 150000,
  'total_pencairan': 200000,
  'saldo': -50000,
};
const _zero = <String, dynamic>{
  'jumlah_transaksi': 0,
  'total_berat': '0.00',
  'total_setoran': 0,
  'total_pencairan': 0,
  'saldo': 0,
};

Future<Either<NetworkException, AktivitasPage>> _response(Object? summary,
    {bool next = false}) async {
  final network = _Network();
  when(() => network.get('/api/v1/aktivitas',
      queryParams: any(named: 'queryParams'))).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
          data: {
            'results': [],
            'next': next ? '/page/2' : null,
            'summary': summary
          }));
  return AktivitasRepositoryImpl(network).history(const TransaksiFilter());
}

Future<AktivitasPage> _page(Map<String, dynamic> totals,
    {bool next = false}) async {
  final result = await _response(totals, next: next);
  return result.fold((error) => throw error, (page) => page);
}

void main() {
  setUpAll(() => registerFallbackValue(const TransaksiFilter()));

  test(
      'positive: parses whole filtered summary, including negative period balance',
      () async {
    final dynamic page = await _page(_totals);
    expect(page.summary.jumlahTransaksi, 25);
    expect(page.summary.totalBerat, 12.5);
    expect(page.summary.totalSetoran, 150000);
    expect(page.summary.totalPencairan, 200000);
    expect(page.summary.saldo, -50000);
  });

  test('corner: empty results preserve genuine zero summary', () async {
    final dynamic page = await _page(_zero);
    expect(page.items, isEmpty);
    expect(page.summary.jumlahTransaksi, 0);
    expect(page.summary.saldo, 0);
  });

  for (final bad in [
    null,
    'invalid',
    {..._totals}..remove('saldo'),
    {..._totals, 'jumlah_transaksi': -1},
    {..._totals, 'jumlah_transaksi': 1.5},
    {..._totals, 'total_setoran': '150000'},
    {..._totals, 'total_pencairan': -1},
    {..._totals, 'total_berat': 'NaN'},
    {..._totals, 'total_berat': '-1.00'},
    {..._totals, 'saldo': 42},
  ]) {
    test('negative: malformed summary fails closed: $bad', () async {
      expect((await _response(bad)).isLeft(), isTrue);
    });
  }

  test(
      'positive: export keeps custom dates, withdrawal type and trimmed search',
      () async {
    final feed = _Feed();
    final export = _Export();
    final cubit = RiwayatAktivitasCubit(feed, export);
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    when(() => export.execute(any())).thenAnswer((_) async => Right(
        TransaksiExport(
            bytes: Uint8List.fromList([1]), filename: 'laporan.xlsx')));
    cubit.applyCustomRange(DateTime(2026, 10, 1), DateTime(2026, 10, 14));
    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);
    cubit.search('  Ani  ');
    await pumpEventQueue();
    expect((await cubit.exportTransaksi()).export?.filename, 'laporan.xlsx');
    final filter = verify(() => export.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.toQueryParams(), {
      'periode': 'custom',
      'dari_tanggal': '2026-10-01',
      'sampai_tanggal': '2026-10-14',
      'tipe': 'pencairan',
      'search': 'Ani',
    });
  });

  test('negative: export failure returns error without a file', () async {
    final export = _Export();
    when(() => export.execute(any())).thenAnswer(
        (_) async => Left(NetworkException(message: 'Tidak diizinkan')));
    final cubit = RiwayatAktivitasCubit(_Feed(), export);
    addTearDown(cubit.close);
    final result = await cubit.exportTransaksi();
    expect(result.export, isNull);
    expect(result.error, 'Tidak diizinkan');
  });

  test(
      'edge: refresh clears stale totals, rejects old request and resets on logout',
      () async {
    final feed = _Feed();
    final cubit = RiwayatAktivitasCubit(feed, _Export());
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    await cubit.load();
    final dynamic loaded = cubit.state;
    expect(loaded.summary.saldo, -50000);
    final old = Completer<Either<NetworkException, AktivitasPage>>();
    when(() => feed.execute(any())).thenAnswer((_) => old.future);
    final pending = cubit.load(silent: true);
    final dynamic loading = cubit.state;
    expect(loading.summary, isNull);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    await cubit.load();
    old.complete(Right(await _page(_totals)));
    await pending;
    final dynamic latest = cubit.state;
    expect(latest.summary.saldo, 0);
    cubit.reset();
    final dynamic reset = cubit.state;
    expect(reset.summary, isNull);
  });

  testWidgets(
      'positive and narrow edge: renders five labeled metrics without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feed = _Feed();
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    final cubit = RiwayatAktivitasCubit(feed, _Export());
    addTearDown(cubit.close);
    await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(value: cubit, child: const LaporanPage())));
    await tester.pumpAndSettle();
    for (final label in [
      'Jumlah transaksi',
      'Total berat',
      'Nilai setoran',
      'Total pencairan',
      'Saldo periode'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('25'), findsOneWidget);
    expect(find.text('12,5 kg'), findsOneWidget);
    expect(find.text('-Rp 50.000'), findsOneWidget);
    expect(find.text('XLSX Laporan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
