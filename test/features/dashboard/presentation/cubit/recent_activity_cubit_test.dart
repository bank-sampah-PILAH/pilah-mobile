import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';

class _MockGetTransaksi extends Mock implements GetTransaksiUseCase {}

class _FakeFilter extends Fake implements TransaksiFilter {}

TransaksiEntity _trx(String name) => TransaksiEntity(
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
    );

/// Flattened names, in order, of whatever the cubit is currently holding.
List<String> _names(RecentActivityState state) => [
      for (final group in (state as RecentActivityLoaded).groups)
        for (final trx in group.transactions) trx.name,
    ];

void main() {
  late _MockGetTransaksi getTransaksi;
  late RecentActivityCubit cubit;

  final oneGroup = [
    TransaksiGroupEntity(header: 'HARI INI', transactions: [_trx('Budi')]),
  ];

  setUpAll(() => registerFallbackValue(_FakeFilter()));

  setUp(() {
    getTransaksi = _MockGetTransaksi();
    cubit = RecentActivityCubit(getTransaksi);
  });

  tearDown(() => cubit.close());

  group('load()', () {
    test('asks for all time — no date filter of any kind', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      await cubit.load();

      final filter =
          verify(() => getTransaksi.execute(captureAny())).captured.single
              as TransaksiFilter;
      expect(filter.periode, TransaksiFilter.periodeSemua);
      expect(filter.dariTanggal, isNull);
      expect(filter.sampaiTanggal, isNull);
      expect(
        filter.toQueryParams().keys,
        ['periode'],
        reason: 'the dashboard shows the latest transactions full stop — a date '
            'param here is what scoped it to the current month',
      );
    });

    test('asks the backend for only as many rows as it shows', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right(oneGroup));

      await cubit.load();

      final filter =
          verify(() => getTransaksi.execute(captureAny())).captured.single
              as TransaksiFilter;
      expect(filter.pageSize, RecentActivityCubit.limit);
    });

    test('keeps only the latest few when the backend returns more', () async {
      when(() => getTransaksi.execute(any())).thenAnswer((_) async => Right([
            TransaksiGroupEntity(
              header: 'HARI INI',
              transactions: [_trx('Budi'), _trx('Sari')],
            ),
            TransaksiGroupEntity(
              header: 'KEMARIN',
              transactions: [_trx('Andi'), _trx('Rina')],
            ),
            TransaksiGroupEntity(
              header: '4 HARI LALU',
              transactions: [_trx('Dewi')],
            ),
          ]));

      await cubit.load();

      expect(_names(cubit.state), ['Budi', 'Sari', 'Andi']);
      expect(
        (cubit.state as RecentActivityLoaded).groups.map((g) => g.header),
        ['HARI INI', 'KEMARIN'],
        reason: 'the day grouping has to survive the trim — it is what labels '
            'each row',
      );
    });

    test('a failure surfaces as an error, not an empty list', () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Left(NetworkException(message: 'boom')));

      await cubit.load();

      expect(cubit.state, isA<RecentActivityError>());
      expect((cubit.state as RecentActivityError).message, 'boom');
    });
  });

  group('load(silent:)', () {
    test('silent from Initial still emits Loading — the section has nothing '
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
