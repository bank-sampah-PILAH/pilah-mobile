import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/edit_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/resend_wa_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';

import '../../../../support/notifier_harness.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/transaksi_state.dart';

class _MockGetTransaksi extends Mock implements GetTransaksiUseCase {}

class _MockGetDetail extends Mock implements GetTransaksiDetailUseCase {}

class _MockAdd extends Mock implements AddTransaksiUseCase {}

class _MockExport extends Mock implements ExportTransaksiUseCase {}

class _MockEdit extends Mock implements EditTransaksiUseCase {}

class _MockResendWa extends Mock implements ResendWaUseCase {}

class _FakeFilter extends Fake implements TransaksiFilter {}

Future<List<TransaksiState>> _capture(
  NotifierHarness<TransaksiNotifier, TransaksiState> harness,
  Future<void> Function() action,
) async {
  final firstEmission = harness.states.length;
  await action();
  return harness.states.skip(firstEmission).toList();
}

void main() {
  late _MockGetTransaksi getTransaksi;
  late TransaksiNotifier cubit;
  late NotifierHarness<TransaksiNotifier, TransaksiState> harness;

  final transaksiGroup = TransaksiGroupEntity(
    header: 'HARI INI',
    transactions: [
      TransaksiEntity(
        id: '1',
        initials: 'BS',
        avatarColor: const Color(0xFF000000),
        textColor: const Color(0xFFFFFFFF),
        name: 'Budi Santoso',
        subtitle: 'Plastik • 2 kg',
        amount: '+Rp 10.000',
        isWaSuccess: true,
        balance: '',
        items: const [],
      ),
    ],
  );

  setUpAll(() => registerFallbackValue(_FakeFilter()));

  setUp(() {
    getTransaksi = _MockGetTransaksi();
    harness = NotifierHarness(
      transaksiProvider,
      () => TransaksiNotifier(
        getTransaksi,
        _MockGetDetail(),
        _MockAdd(),
        _MockExport(),
        _MockResendWa(),
        _MockEdit(),
      ),
    );
    cubit = harness.notifier;
  });

  tearDown(() => harness.dispose());

  group('loadTransaksi(silent:)', () {
    test('silent from Initial still emits Loading — the UI has nothing to show',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right([transaksiGroup]));

      expect(cubit.state, isA<TransaksiInitial>());
      final emitted =
          await _capture(harness, () => cubit.loadTransaksi(silent: true));

      expect(
        emitted.first,
        isA<TransaksiLoading>(),
        reason: 'silent must not suppress the first load off Initial',
      );
      expect(emitted.last, isA<TransaksiLoaded>());
    });

    test('silent from Error still emits Loading — the error view has no data',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Left(NetworkException(message: 'boom')));
      await cubit.loadTransaksi();
      expect(cubit.state, isA<TransaksiError>());

      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right([transaksiGroup]));

      final emitted =
          await _capture(harness, () => cubit.loadTransaksi(silent: true));

      expect(
        emitted.first,
        isA<TransaksiLoading>(),
        reason: 'silent must not suppress recovery from an error state',
      );
      expect(emitted.last, isA<TransaksiLoaded>());
    });

    test('silent from Loaded keeps the list on screen (no Loading emitted)',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right([transaksiGroup]));
      await cubit.loadTransaksi();
      expect(cubit.state, isA<TransaksiLoaded>());

      final emitted =
          await _capture(harness, () => cubit.loadTransaksi(silent: true));

      expect(
        emitted.whereType<TransaksiLoading>(),
        isEmpty,
        reason: 'pull-to-refresh must not collapse a populated list',
      );
      // Guards against the assertion above passing vacuously: the refresh must
      // still have delivered a state.
      expect(emitted.last, isA<TransaksiLoaded>());
    });

    test('reset() returns to Initial so the next session starts clean',
        () async {
      when(() => getTransaksi.execute(any()))
          .thenAnswer((_) async => Right([transaksiGroup]));
      await cubit.loadTransaksi();
      expect(cubit.state, isA<TransaksiLoaded>());

      cubit.reset();

      expect(cubit.state, isA<TransaksiInitial>());
    });
  });
}
