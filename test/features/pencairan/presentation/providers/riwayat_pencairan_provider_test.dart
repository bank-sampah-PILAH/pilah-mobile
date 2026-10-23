import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/states/riwayat_pencairan_state.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/riwayat_pencairan_provider.dart';
import 'package:pilah_mobile/services/di.dart';

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
const _filter = RiwayatPencairanFilter(periode: RiwayatPeriode.bulanIni);

void main() {
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));

  late _MockUseCases useCases;
  late ProviderContainer container;

  setUp(() {
    useCases = _MockUseCases();
    when(() => useCases.getRiwayat(any()))
        .thenAnswer((_) async => const Right([_row]));
    container = ProviderContainer(overrides: [
      riwayatPencairanProvider.overrideWith(
        () => RiwayatPencairanNotifier(useCases),
      ),
    ]);
    addTearDown(container.dispose);
  });

  test('starts in the initial state', () {
    expect(container.read(riwayatPencairanProvider),
        const RiwayatPencairanState());
  });

  test('loads the riwayat for the filter', () async {
    final states = <RiwayatPencairanState>[];
    final subscription = container.listen(
      riwayatPencairanProvider,
      (_, state) => states.add(state),
    );
    addTearDown(subscription.close);

    await container.read(riwayatPencairanProvider.notifier).load(_filter);

    expect(states, const [
      RiwayatPencairanState(
        status: RiwayatStatus.loading,
        filter: _filter,
      ),
      RiwayatPencairanState(
        status: RiwayatStatus.loaded,
        filter: _filter,
        items: [_row],
      ),
    ]);
  });

  test('reports a riwayat that cannot be loaded', () async {
    when(() => useCases.getRiwayat(any())).thenAnswer(
      (_) async => Left(FetchDataException(message: 'Server tidak merespons')),
    );

    await container.read(riwayatPencairanProvider.notifier).load(_filter);

    expect(
        container.read(riwayatPencairanProvider),
        const RiwayatPencairanState(
          status: RiwayatStatus.failure,
          filter: _filter,
          errorMessage: 'Server tidak merespons',
        ));
  });

  test('keeps the existing rows visible while loading a new filter', () async {
    final notifier = container.read(riwayatPencairanProvider.notifier);
    await notifier.load(_filter);
    final pending = Completer<Either<NetworkException, List<Pencairan>>>();
    const nextFilter =
        RiwayatPencairanFilter(periode: RiwayatPeriode.bulanLalu);
    when(() => useCases.getRiwayat(nextFilter))
        .thenAnswer((_) => pending.future);

    final request = notifier.load(nextFilter);

    expect(
        container.read(riwayatPencairanProvider),
        const RiwayatPencairanState(
          status: RiwayatStatus.loading,
          filter: nextFilter,
          items: [_row],
        ));
    pending.complete(const Right([]));
    await request;
  });

  test('reloads with a changed periode but not the same periode', () async {
    final notifier = container.read(riwayatPencairanProvider.notifier);
    await notifier.load(_filter);
    await notifier.setPeriode(RiwayatPeriode.bulanIni);
    verify(() => useCases.getRiwayat(_filter)).called(1);

    const nextFilter =
        RiwayatPencairanFilter(periode: RiwayatPeriode.bulanLalu);
    await notifier.setPeriode(RiwayatPeriode.bulanLalu);
    verify(() => useCases.getRiwayat(nextFilter)).called(1);
  });

  test('reloads with the search text and current periode', () async {
    await container.read(riwayatPencairanProvider.notifier).load(_filter);
    await container.read(riwayatPencairanProvider.notifier).setSearch('siti');

    verify(() => useCases.getRiwayat(
          const RiwayatPencairanFilter(
            periode: RiwayatPeriode.bulanIni,
            search: 'siti',
          ),
        )).called(1);
  });

  test('a slower earlier filter cannot overwrite the current result', () async {
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
    final notifier = container.read(riwayatPencairanProvider.notifier);

    final earlier = notifier.load(stale);
    await notifier.load(current);
    slow.complete(const Right([staleRow]));
    await earlier;

    expect(
        container.read(riwayatPencairanProvider),
        const RiwayatPencairanState(
          status: RiwayatStatus.loaded,
          filter: current,
          items: [_row],
        ));
  });

  test('ignores an in-flight response after disposal', () async {
    final slow = Completer<Either<NetworkException, List<Pencairan>>>();
    when(() => useCases.getRiwayat(any())).thenAnswer((_) => slow.future);
    final request =
        container.read(riwayatPencairanProvider.notifier).load(_filter);

    container.dispose();
    slow.complete(const Right([_row]));
    await expectLater(request, completes);
  });

  test('resolves use cases from DI', () async {
    di.registerSingleton<PencairanUseCases>(useCases);
    addTearDown(() => di.unregister<PencairanUseCases>());
    final diContainer = ProviderContainer();
    addTearDown(diContainer.dispose);

    await diContainer.read(riwayatPencairanProvider.notifier).load(_filter);

    verify(() => useCases.getRiwayat(_filter)).called(1);
  });
}
