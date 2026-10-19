import 'dart:typed_data';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class Feed extends Mock implements GetAktivitasUseCase {}

class Export extends Mock implements ExportTransaksiUseCase {}

void main() {
  setUpAll(() => registerFallbackValue(const TransaksiFilter()));
  test('export retains the current period and reset clears all filters',
      () async {
    final feed = Feed();
    final export = Export();
    final cubit = RiwayatAktivitasCubit(feed, export);
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    final expected =
        TransaksiExport(bytes: Uint8List.fromList([1]), filename: 'test.xlsx');
    when(() => export.execute(any())).thenAnswer((_) async => Right(expected));
    cubit.applyCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    await Future<void>.delayed(Duration.zero);
    expect((await cubit.exportTransaksi()).export, expected);
    final filter = verify(() => export.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.periode, 'custom');
    expect(filter.dariTanggal, DateTime(2026, 9, 1));
    cubit.reset();
    expect(cubit.state, const RiwayatAktivitasState());
  });

  test('resetFilters returns to the default view and reloads the feed',
      () async {
    final feed = Feed();
    final cubit = RiwayatAktivitasCubit(feed, Export());
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);
    cubit.setPeriode('12_bulan');
    cubit.search('Budi');
    await Future<void>.delayed(Duration.zero);
    clearInteractions(feed);

    cubit.resetFilters();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tipeFilter, AktivitasTipeFilter.semua);
    expect(cubit.state.periode, 'bulan_ini');
    expect(cubit.state.search, isEmpty);
    expect(cubit.state.status, AktivitasStatus.loaded);
    verify(() => feed.execute(any())).called(1);
  });

  test('filtered feeds invoke the unified XLSX export', () async {
    final feed = Feed();
    final export = Export();
    final cubit = RiwayatAktivitasCubit(feed, export);
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    when(() => export.execute(any())).thenAnswer((_) async =>
        Right(TransaksiExport(bytes: Uint8List(0), filename: 'all.xlsx')));
    for (final type in [
      AktivitasTipeFilter.setoran,
      AktivitasTipeFilter.pencairan
    ]) {
      cubit.setTipeFilter(type);
      await Future<void>.delayed(Duration.zero);
      final result = await cubit.exportTransaksi();
      expect(result.export, isNotNull);
      expect(result.error, isNull);
    }
    cubit.setTipeFilter(AktivitasTipeFilter.semua);
    cubit.search('Budi');
    await Future<void>.delayed(Duration.zero);
    expect((await cubit.exportTransaksi()).export, isNotNull);
    verify(() => export.execute(any())).called(3);
    cubit.search('   ');
    await Future<void>.delayed(Duration.zero);
    expect((await cubit.exportTransaksi()).export, isNotNull);
    verify(() => export.execute(any())).called(1);
  });

  group('server feed lifecycle', () {
    late Feed feed;
    late Export export;
    late RiwayatAktivitasCubit cubit;
    setUp(() {
      feed = Feed();
      export = Export();
      cubit = RiwayatAktivitasCubit(feed, export);
      when(() => feed.execute(any()))
          .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    });
    tearDown(() async {
      if (!cubit.isClosed) await cubit.close();
    });
    test('last month is sent to the unified API', () async {
      cubit.setPeriode('bulan_lalu');
      await pumpEventQueue();
      final filter = verify(() => feed.execute(captureAny())).captured.single
          as TransaksiFilter;
      expect(filter.periode, 'bulan_lalu');
    });
    test('reselecting current period is a no-op', () async {
      cubit.setPeriode('bulan_ini');
      await pumpEventQueue();
      verifyNever(() => feed.execute(any()));
    });
    test('closing mid-load never emits a late response', () async {
      final pending = cubit.load();
      await cubit.close();
      await pending;
    });
    test('export failure keeps its message', () async {
      when(() => export.execute(any())).thenAnswer(
          (_) async => Left(NetworkException(message: 'Tidak ada data')));
      final result = await cubit.exportTransaksi();
      expect(result.export, isNull);
      expect(result.error, 'Tidak ada data');
    });
    test('copyWith preserves unrelated fields', () {
      const state = RiwayatAktivitasState(search: 'abc');
      expect(state.copyWith(periode: 'bulan_lalu').search, 'abc');
    });
  });
}
