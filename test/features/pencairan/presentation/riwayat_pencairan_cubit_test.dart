import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_state.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

const _row = Pencairan(
  id: 'p-1',
  nasabahId: 'n-1',
  nasabahNama: 'Ahmad Ridwan',
  nominal: 200000,
  metode: MetodePencairan.tunai,
  tanggal: null,
  keterangan: 'Diambil pagi',
  status: 'tercatat',
  saldoSebelum: 465600,
  saldoSesudah: 265600,
);

const _bankWide = RiwayatPencairanFilter(periode: RiwayatPeriode.bulanIni);

void main() {
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));

  late _MockUseCases useCases;

  setUp(() {
    useCases = _MockUseCases();
    when(() => useCases.getRiwayat(any()))
        .thenAnswer((_) async => const Right([_row]));
  });

  blocTest<RiwayatPencairanCubit, RiwayatPencairanState>(
    'loads the riwayat for the filter',
    build: () => RiwayatPencairanCubit(useCases),
    act: (cubit) => cubit.load(_bankWide),
    expect: () => const [
      RiwayatPencairanState(
        status: RiwayatStatus.loading,
        filter: _bankWide,
      ),
      RiwayatPencairanState(
        status: RiwayatStatus.loaded,
        filter: _bankWide,
        items: [_row],
      ),
    ],
  );

  blocTest<RiwayatPencairanCubit, RiwayatPencairanState>(
    'reports a riwayat that cannot be loaded',
    build: () {
      when(() => useCases.getRiwayat(any())).thenAnswer(
        (_) async =>
            Left(FetchDataException(message: 'Server tidak merespons')),
      );
      return RiwayatPencairanCubit(useCases);
    },
    act: (cubit) => cubit.load(_bankWide),
    skip: 1,
    expect: () => const [
      RiwayatPencairanState(
        status: RiwayatStatus.failure,
        filter: _bankWide,
        errorMessage: 'Server tidak merespons',
      ),
    ],
  );

  blocTest<RiwayatPencairanCubit, RiwayatPencairanState>(
    'reloads with the chosen periode',
    build: () => RiwayatPencairanCubit(useCases),
    seed: () => const RiwayatPencairanState(
      status: RiwayatStatus.loaded,
      filter: _bankWide,
      items: [_row],
    ),
    act: (cubit) => cubit.setPeriode(RiwayatPeriode.bulanLalu),
    verify: (_) => verify(
      () => useCases.getRiwayat(
        const RiwayatPencairanFilter(periode: RiwayatPeriode.bulanLalu),
      ),
    ).called(1),
  );

  blocTest<RiwayatPencairanCubit, RiwayatPencairanState>(
    'reloads with the search text',
    build: () => RiwayatPencairanCubit(useCases),
    seed: () => const RiwayatPencairanState(
      status: RiwayatStatus.loaded,
      filter: _bankWide,
    ),
    act: (cubit) => cubit.setSearch('siti'),
    verify: (_) => verify(
      () => useCases.getRiwayat(
        const RiwayatPencairanFilter(
          periode: RiwayatPeriode.bulanIni,
          search: 'siti',
        ),
      ),
    ).called(1),
  );

  blocTest<RiwayatPencairanCubit, RiwayatPencairanState>(
    'does not reload for the periode already shown',
    build: () => RiwayatPencairanCubit(useCases),
    seed: () => const RiwayatPencairanState(
      status: RiwayatStatus.loaded,
      filter: _bankWide,
    ),
    act: (cubit) => cubit.setPeriode(RiwayatPeriode.bulanIni),
    expect: () => const <RiwayatPencairanState>[],
    verify: (_) => verifyNever(() => useCases.getRiwayat(any())),
  );

  test('ignores a response for a filter the user has moved on from', () async {
    const stale = RiwayatPencairanFilter(periode: RiwayatPeriode.bulanLalu);
    const current = RiwayatPencairanFilter(periode: RiwayatPeriode.semua);
    const staleRow = Pencairan(
      id: 'p-old',
      nasabahNama: 'Bulan Lalu',
      nominal: 1000,
      metode: MetodePencairan.tunai,
      tanggal: null,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 0,
      saldoSesudah: 0,
    );
    final slow = Completer<Either<NetworkException, List<Pencairan>>>();
    when(() => useCases.getRiwayat(stale)).thenAnswer((_) => slow.future);
    when(() => useCases.getRiwayat(current))
        .thenAnswer((_) async => const Right([_row]));
    final cubit = RiwayatPencairanCubit(useCases);

    final first = cubit.load(stale);
    await cubit.load(current);
    slow.complete(const Right([staleRow]));
    await first;

    expect(cubit.state.filter, current);
    expect(cubit.state.items, const [_row]);
    await cubit.close();
  });

  test('does not emit after the page is closed', () async {
    final slow = Completer<Either<NetworkException, List<Pencairan>>>();
    when(() => useCases.getRiwayat(any())).thenAnswer((_) => slow.future);
    final cubit = RiwayatPencairanCubit(useCases);

    final inFlight = cubit.load(_bankWide);
    await cubit.close();
    slow.complete(const Right([_row]));

    await expectLater(inFlight, completes);
  });
}
