import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_state.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);

void main() {
  late _MockUseCases useCases;
  late PilihNasabahCubit cubit;

  void answer({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    int saldoMin = 0,
    required List<Kandidat> rows,
  }) {
    when(() => useCases.getKandidat(
          search: search,
          urutan: urutan,
          saldoMin: saldoMin,
        )).thenAnswer((_) async => Right(rows));
  }

  setUp(() async {
    useCases = _MockUseCases();
    answer(rows: [_ahmad, _budi, _citra]);
    cubit = PilihNasabahCubit(useCases);
    await cubit.load();
  });

  test('lists every nasabah who can be paid out, none picked yet', () {
    expect(cubit.state.status, PilihStatus.loaded);
    expect(cubit.state.kandidat, [_ahmad, _budi, _citra]);
    expect(cubit.state.selectedIds, isEmpty);
    expect(cubit.state.jumlahTerpilih, 0);
  });

  test('picking and un-picking one nasabah tracks the count and saldo', () {
    cubit.toggle('n-1');
    cubit.toggle('n-2');
    cubit.toggle('n-1');

    expect(cubit.state.selectedIds, {'n-2'});
    expect(cubit.state.jumlahTerpilih, 1);
    expect(cubit.state.saldoTerpilih, 50000);
  });

  test('searching and sorting ask the server, and the picks survive', () async {
    cubit.toggle('n-1');
    answer(search: 'bud', rows: [_budi]);
    await cubit.setSearch('bud');

    expect(cubit.state.kandidat, [_budi]);
    expect(cubit.state.selectedIds, {'n-1'});
    expect(cubit.state.saldoTerpilih, 465600,
        reason: 'a pick hidden by the search still counts');

    answer(search: 'bud', urutan: KandidatUrutan.saldoTerbesar, rows: [_budi]);
    await cubit.setUrutan(KandidatUrutan.saldoTerbesar);

    verify(() => useCases.getKandidat(
          search: 'bud',
          urutan: KandidatUrutan.saldoTerbesar,
          saldoMin: 0,
        )).called(1);
  });

  test('select all picks everyone, even people the search is hiding', () async {
    answer(search: 'bud', rows: [_budi]);
    await cubit.setSearch('bud');

    await cubit.pilihSemua();

    expect(cubit.state.selectedIds, {'n-1', 'n-2', 'n-3'});
    expect(cubit.state.kandidat, [_budi], reason: 'the visible list is kept');
  });

  test('select the search results adds only what is shown', () async {
    cubit.toggle('n-1');
    answer(search: 'i', rows: [_budi, _citra]);
    await cubit.setSearch('i');

    cubit.pilihHasilPencarian();

    expect(cubit.state.selectedIds, {'n-1', 'n-2', 'n-3'});
  });

  test('select by minimum saldo adds those who have at least that much',
      () async {
    answer(saldoMin: 200000, rows: [_ahmad, _citra]);

    await cubit.pilihSaldoMin(200000);

    expect(cubit.state.selectedIds, {'n-1', 'n-3'});
    verify(() => useCases.getKandidat(
        search: '', urutan: KandidatUrutan.namaAZ, saldoMin: 200000)).called(1);
  });

  test('invert flips the picks within the list on screen', () {
    cubit.toggle('n-1');

    cubit.balikkan();

    expect(cubit.state.selectedIds, {'n-2', 'n-3'});
  });

  test('clear drops every pick', () {
    cubit.toggle('n-1');
    cubit.toggle('n-2');

    cubit.kosongkan();

    expect(cubit.state.selectedIds, isEmpty);
    expect(cubit.state.saldoTerpilih, 0);
  });

  test('the picked nasabah come back in name order for the editor', () async {
    cubit.toggle('n-3');
    cubit.toggle('n-1');

    expect(cubit.state.terpilih, [_ahmad, _citra]);
  });

  test('a failed load says why', () async {
    when(() => useCases.getKandidat(
          search: '',
          urutan: KandidatUrutan.namaAZ,
          saldoMin: 0,
        )).thenAnswer((_) async => Left(ConnectionTimeOutException()));

    await cubit.load();

    expect(cubit.state.status, PilihStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('a slow answer for an old search never overwrites the newer one',
      () async {
    final slow = Completer<Either<NetworkException, List<Kandidat>>>();
    when(() => useCases.getKandidat(
          search: 'a',
          urutan: KandidatUrutan.namaAZ,
          saldoMin: 0,
        )).thenAnswer((_) => slow.future);
    answer(search: 'ab', rows: [_ahmad]);

    final first = cubit.setSearch('a');
    await cubit.setSearch('ab');
    slow.complete(Right([_budi, _citra]));
    await first;

    expect(cubit.state.kandidat, [_ahmad]);
    expect(cubit.state.search, 'ab');
  });
}
