import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class _MockGetTransaksiUseCase extends Mock implements GetTransaksiUseCase {}

class _MockPencairanUseCases extends Mock implements PencairanUseCases {}

class _MockExportTransaksiUseCase extends Mock
    implements ExportTransaksiUseCase {}

TransaksiEntity _setoran(String name, DateTime tanggal) => TransaksiEntity(
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      name: name,
      subtitle: 'Plastik PET • 2 kg',
      amount: '+Rp 7.000',
      isWaSuccess: true,
      balance: 'Rp 0',
      items: const [],
      tanggal: tanggal,
    );

Pencairan _pencairan(String name, DateTime tanggal) => Pencairan(
      id: 'p-1',
      nasabahNama: name,
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
    registerFallbackValue(const RiwayatPencairanFilter());
  });

  late _MockGetTransaksiUseCase getTransaksi;
  late _MockPencairanUseCases pencairanUseCases;
  late _MockExportTransaksiUseCase exportTransaksi;
  late RiwayatAktivitasCubit cubit;

  setUp(() {
    getTransaksi = _MockGetTransaksiUseCase();
    pencairanUseCases = _MockPencairanUseCases();
    exportTransaksi = _MockExportTransaksiUseCase();
    cubit =
        RiwayatAktivitasCubit(getTransaksi, pencairanUseCases, exportTransaksi);
  });

  tearDown(() => cubit.close());

  test('merges setoran and pencairan sorted by newest first', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani', DateTime(2026, 9, 22, 10))]),
    );

    await cubit.load();

    expect(cubit.state.items.map((e) => e.title), ['Ani', 'Budi']);
    expect(cubit.state.items[0].tipe, ActivitasTipe.pencairan);
    expect(cubit.state.items[1].tipe, ActivitasTipe.setoran);
  });

  test('degrades to setoran-only when the pencairan fetch fails', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Layanan sibuk')),
    );

    await cubit.load();

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Budi');
  });

  test('surfaces a failure when the setoran fetch itself fails', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Gagal memuat')),
    );

    await cubit.load();

    expect(cubit.state.status, AktivitasStatus.failure);
    expect(cubit.state.errorMessage, 'Gagal memuat');
    verifyNever(() => pencairanUseCases.getRiwayat(any()));
  });

  test('skips the pencairan fetch for a custom setoran date range', () async {
    when(() => getTransaksi.execute(any())).thenAnswer((_) async => Right([]));

    cubit.applyCustomRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => pencairanUseCases.getRiwayat(any()));
  });

  test('filters by tipe without refetching', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani', DateTime(2026, 9, 22, 10))]),
    );
    await cubit.load();

    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Ani');
    verify(() => getTransaksi.execute(any())).called(1);
  });

  test('searches by name across both types', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi Santoso', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10))]),
    );
    await cubit.load();

    cubit.search('budi');

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Budi Santoso');
  });

  group('period handling', () {
    void stubFeeds({List<TransaksiGroupEntity> groups = const []}) {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(groups));
      when(() => pencairanUseCases.getRiwayat(any()))
          .thenAnswer((_) async => const Right([]));
    }

    test('last month loads the matching pencairan period', () async {
      stubFeeds();

      cubit.setPeriode('bulan_lalu');
      await pumpEventQueue();

      final filter = verify(() => pencairanUseCases.getRiwayat(captureAny()))
          .captured
          .single as RiwayatPencairanFilter;
      expect(filter.periode, RiwayatPeriode.bulanLalu);
      expect(cubit.state.periode, 'bulan_lalu');
    });

    test('re-selecting the current period is a no-op', () async {
      stubFeeds();

      cubit.setPeriode('bulan_ini');
      await pumpEventQueue();

      verifyNever(() => getTransaksi.execute(any()));
    });

    test('a custom range is reflected in state', () async {
      stubFeeds();

      cubit.applyCustomRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      await pumpEventQueue();

      expect(cubit.state.isCustomPeriode, isTrue);
      expect(cubit.state.dariTanggal, DateTime(2026, 1, 1));
      expect(cubit.state.sampaiTanggal, DateTime(2026, 1, 31));

      // Leaving a custom range for "custom" again still refetches, because the
      // dates are cleared.
      cubit.setPeriode('custom');
      await pumpEventQueue();
      verify(() => getTransaksi.execute(any())).called(2);
      expect(cubit.state.dariTanggal, isNull);
    });

    test('a silent refresh keeps the loaded list on screen', () async {
      stubFeeds();
      await cubit.load();
      final statuses = <AktivitasStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.status));

      await cubit.load(silent: true);
      await pumpEventQueue();
      await sub.cancel();

      expect(statuses, isNot(contains(AktivitasStatus.loading)));
    });

    test('undated entries sink below dated ones', () async {
      when(() => getTransaksi.execute(any())).thenAnswer(
        (_) async => Right([
          TransaksiGroupEntity(header: 'X', transactions: [
            TransaksiEntity(
              initials: 'UN',
              avatarColor: const Color(0xFF000000),
              textColor: const Color(0xFFFFFFFF),
              name: 'Undated',
              subtitle: '',
              amount: '',
              isWaSuccess: false,
              balance: '',
              items: const [],
            ),
            _setoran('Dated', DateTime(2026, 9, 22)),
            _setoran('Older', DateTime(2026, 9, 1)),
            TransaksiEntity(
              initials: 'U2',
              avatarColor: const Color(0xFF000000),
              textColor: const Color(0xFFFFFFFF),
              name: 'Undated 2',
              subtitle: '',
              amount: '',
              isWaSuccess: false,
              balance: '',
              items: const [],
            ),
            _setoran('Newest', DateTime(2026, 9, 30)),
          ]),
        ]),
      );
      when(() => pencairanUseCases.getRiwayat(any()))
          .thenAnswer((_) async => const Right([]));

      await cubit.load();

      expect(cubit.state.items.map((e) => e.title),
          ['Newest', 'Dated', 'Older', 'Undated', 'Undated 2']);
    });

    test('a dated entry ahead of an undated one stays ahead', () async {
      when(() => getTransaksi.execute(any())).thenAnswer(
        (_) async => Right([
          TransaksiGroupEntity(header: 'X', transactions: [
            _setoran('Dated', DateTime(2026, 9, 22)),
            TransaksiEntity(
              initials: 'UN',
              avatarColor: const Color(0xFF000000),
              textColor: const Color(0xFFFFFFFF),
              name: 'Undated',
              subtitle: '',
              amount: '',
              isWaSuccess: false,
              balance: '',
              items: const [],
            ),
          ]),
        ]),
      );
      when(() => pencairanUseCases.getRiwayat(any()))
          .thenAnswer((_) async => const Right([]));

      await cubit.load();

      expect(cubit.state.items.map((e) => e.title), ['Dated', 'Undated']);
    });

    test('closing mid-load does not emit afterwards', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Left(NetworkException(message: 'x')));

      final pending = cubit.load();
      await cubit.close();
      await pending;
    });

    test('closing while pencairan loads does not emit afterwards', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => pencairanUseCases.getRiwayat(any())).thenAnswer((_) async {
        await cubit.close();
        return const Right([]);
      });

      await cubit.load();
    });
  });

  group('export and reset', () {
    test('export hands back the file for the current period', () async {
      final export = TransaksiExport(bytes: Uint8List(1), filename: 'a.xlsx');
      when(() => exportTransaksi.execute(any()))
          .thenAnswer((_) async => Right(export));

      final result = await cubit.exportTransaksi();

      expect(result.export, export);
      expect(result.error, isNull);
    });

    test('export reports the failure message', () async {
      when(() => exportTransaksi.execute(any())).thenAnswer(
          (_) async => Left(NetworkException(message: 'Tidak ada data')));

      final result = await cubit.exportTransaksi();

      expect(result.export, isNull);
      expect(result.error, 'Tidak ada data');
    });

    test('reset drops the cache and filters', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => pencairanUseCases.getRiwayat(any()))
          .thenAnswer((_) async => const Right([]));
      await cubit.load();
      cubit.setTipeFilter(AktivitasTipeFilter.setoran);
      cubit.search('x');

      cubit.reset();

      expect(cubit.state, const RiwayatAktivitasState());
    });

    test('copyWith keeps untouched fields', () {
      const state = RiwayatAktivitasState(search: 'abc');

      expect(state.copyWith(periode: 'bulan_lalu').search, 'abc');
      expect(state.copyWith(periode: 'bulan_lalu').periode, 'bulan_lalu');
    });
  });
}
