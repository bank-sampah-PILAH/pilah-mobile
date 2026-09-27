import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';

class _MockGetTransaksi extends Mock implements GetTransaksiUseCase {}

class _MockPencairanUseCases extends Mock implements PencairanUseCases {}

class _FakeFilter extends Fake implements TransaksiFilter {}

TransaksiEntity _trx(String name, {DateTime? tanggal}) => TransaksiEntity(
      id: name,
      initials: 'XX',
      avatarColor: const Color(0xFF000000),
      textColor: const Color(0xFFFFFFFF),
      name: name,
      subtitle: 'Plastik • 2 kg',
      amount: '+Rp 10.000',
      isWaSuccess: true,
      balance: '',
      items: const [],
      tanggal: tanggal,
    );

Pencairan _pencairan(String name, DateTime tanggal) => Pencairan(
      id: name,
      nasabahNama: name,
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
    );

/// Titles, in order, of whatever the cubit is currently holding.
List<String> _titles(RecentActivityState state) =>
    (state as RecentActivityLoaded).items.map((e) => e.title).toList();

void main() {
  late _MockGetTransaksi getTransaksi;
  late _MockPencairanUseCases pencairanUseCases;
  late RecentActivityCubit cubit;

  final oneGroup = [
    TransaksiGroupEntity(header: 'HARI INI', transactions: [_trx('Budi')]),
  ];

  setUpAll(() {
    registerFallbackValue(_FakeFilter());
    registerFallbackValue(const RiwayatPencairanFilter());
  });

  setUp(() {
    getTransaksi = _MockGetTransaksi();
    pencairanUseCases = _MockPencairanUseCases();
    when(() => pencairanUseCases.getRiwayat(any()))
        .thenAnswer((_) async => const Right([]));
    cubit = RecentActivityCubit(getTransaksi, pencairanUseCases);
  });

  tearDown(() => cubit.close());

  group('load()', () {
    test('asks for all time — no date filter of any kind', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      await cubit.load();

      final filter = verify(() => getTransaksi.execute(captureAny()))
          .captured
          .single as TransaksiFilter;
      expect(filter.periode, TransaksiFilter.periodeSemua);
      expect(filter.dariTanggal, isNull);
      expect(filter.sampaiTanggal, isNull);
      expect(
        filter.toQueryParams().keys,
        ['periode'],
        reason:
            'the dashboard shows the latest transactions full stop — a date '
            'param here is what scoped it to the current month',
      );
    });

    test('also asks for the whole pencairan history', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      await cubit.load();

      final filter = verify(() => pencairanUseCases.getRiwayat(captureAny()))
          .captured
          .single as RiwayatPencairanFilter;
      expect(filter.periode, RiwayatPeriode.semua);
    });

    test('asks the backend for only as many setoran rows as it shows',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      await cubit.load();

      final filter = verify(() => getTransaksi.execute(captureAny()))
          .captured
          .single as TransaksiFilter;
      expect(filter.pageSize, RecentActivityCubit.limit);
    });

    test('merges setoran and pencairan, newest first, capped at the limit',
        () async {
      when(() => getTransaksi.execute(any())).thenAnswer((_) async => Right([
            TransaksiGroupEntity(
              header: 'HARI INI',
              transactions: [
                _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
                _trx('Sari', tanggal: DateTime(2026, 9, 22, 8)),
              ],
            ),
          ]));
      when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
        (_) async => Right([_pencairan('Ani', DateTime(2026, 9, 22, 10))]),
      );

      await cubit.load();

      expect(_titles(cubit.state), ['Ani', 'Budi', 'Sari']);
    });

    test('degrades to setoran-only when the pencairan fetch fails', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));
      when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
        (_) async => Left(NetworkException(message: 'boom')),
      );

      await cubit.load();

      expect(_titles(cubit.state), ['Budi']);
    });

    test('a failure surfaces as an error, not an empty list', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Left(NetworkException(message: 'boom')));

      await cubit.load();

      expect(cubit.state, isA<RecentActivityError>());
      expect((cubit.state as RecentActivityError).message, 'boom');
      verifyNever(() => pencairanUseCases.getRiwayat(any()));
    });
  });

  group('load(silent:)', () {
    test(
        'silent from Initial still emits Loading — the section has nothing '
        'to show', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      final emitted = <RecentActivityState>[];
      final sub = cubit.stream.listen(emitted.add);
      await cubit.load(silent: true);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.first, isA<RecentActivityLoading>());
      expect(emitted.last, isA<RecentActivityLoaded>());
    });

    test('silent from Loaded keeps the list on screen (no Loading emitted)',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));
      await cubit.load();
      expect(cubit.state, isA<RecentActivityLoaded>());

      final emitted = <RecentActivityState>[];
      final sub = cubit.stream.listen(emitted.add);
      await cubit.load(silent: true);
      await pumpEventQueue();
      await sub.cancel();

      expect(
        emitted.whereType<RecentActivityLoading>(),
        isEmpty,
        reason: 'pull-to-refresh must not collapse a populated list',
      );
      // Guards against the assertion above passing vacuously.
      expect(emitted.last, isA<RecentActivityLoaded>());
    });
  });

  test('reset() returns to Initial so the next session starts clean', () async {
    when(() => getTransaksi.execute(any()))
        .thenAnswer((_) async => Right(oneGroup));
    await cubit.load();
    expect(cubit.state, isA<RecentActivityLoaded>());

    cubit.reset();

    expect(cubit.state, isA<RecentActivityInitial>());
  });
}
