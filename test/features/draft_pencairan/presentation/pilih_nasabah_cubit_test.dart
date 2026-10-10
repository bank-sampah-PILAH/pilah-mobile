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
const _fani =
    Kandidat(id: 'n-4', kode: 'NAS-0004', nama: 'Fani Kosong', saldo: 0);

void main() {
  late _MockUseCases useCases;
  late PilihNasabahCubit cubit;

  void answer({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    required List<Kandidat> rows,
  }) {
    when(() => useCases.getKandidat(
          search: search,
          urutan: urutan,
          termasukKosong: true,
        )).thenAnswer((_) async => Right(rows));
  }

  setUp(() async {
    useCases = _MockUseCases();
    answer(rows: [_ahmad, _budi, _citra, _fani]);
    cubit = PilihNasabahCubit(useCases);
    await cubit.load();
  });

  test('lists everyone, nasabah without saldo included, none picked yet', () {
    expect(cubit.state.status, PilihStatus.loaded);
    expect(cubit.state.kandidat, [_ahmad, _budi, _citra, _fani]);
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

  test('a nasabah without saldo cannot be picked', () {
    cubit.toggle('n-4');

    expect(cubit.state.selectedIds, isEmpty);
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
          termasukKosong: true,
        )).called(1);
  });

  group('sorting by field', () {
    test('name starts A to Z, and again flips to Z to A', () async {
      answer(urutan: KandidatUrutan.namaZA, rows: [_fani, _citra]);
      await cubit.setSortField(KandidatSortField.nama);

      expect(cubit.state.urutan, KandidatUrutan.namaZA);
    });

    test('saldo starts with the biggest, and again flips to the smallest',
        () async {
      answer(urutan: KandidatUrutan.saldoTerbesar, rows: [_ahmad]);
      await cubit.setSortField(KandidatSortField.saldo);
      expect(cubit.state.urutan, KandidatUrutan.saldoTerbesar);

      answer(urutan: KandidatUrutan.saldoTerkecil, rows: [_fani]);
      await cubit.setSortField(KandidatSortField.saldo);
      expect(cubit.state.urutan, KandidatUrutan.saldoTerkecil);
    });

    test('every order knows its field and direction', () {
      expect(KandidatUrutan.namaAZ.field, KandidatSortField.nama);
      expect(KandidatUrutan.namaAZ.ascending, isTrue);
      expect(KandidatUrutan.saldoTerbesar.field, KandidatSortField.saldo);
      expect(KandidatUrutan.saldoTerbesar.ascending, isFalse);
    });
  });

  group('filters', () {
    test('show everyone by default', () {
      expect(cubit.state.tampil, [_ahmad, _budi, _citra, _fani]);
    });

    test('only the picked, or only those not picked yet', () {
      cubit.toggle('n-1');

      cubit.setFilter(PilihFilter.terpilih);
      expect(cubit.state.tampil, [_ahmad]);

      cubit.setFilter(PilihFilter.belumDipilih);
      expect(cubit.state.tampil, [_budi, _citra, _fani]);
    });

    test('only those without saldo', () {
      cubit.setFilter(PilihFilter.saldoKosong);

      expect(cubit.state.tampil, [_fani]);
    });

    test('a minimum saldo narrows the list, and zero clears it', () {
      cubit.setSaldoMin(200000);
      expect(cubit.state.tampil, [_ahmad, _citra]);

      cubit.setSaldoMin(0);
      expect(cubit.state.tampil, hasLength(4));
    });

    test('a minimum saldo combines with a status filter', () {
      cubit.toggle('n-1');
      cubit.setSaldoMin(200000);
      cubit.setFilter(PilihFilter.belumDipilih);

      expect(cubit.state.tampil, [_citra]);
    });

    test('counts say how many each filter holds', () {
      cubit.toggle('n-1');
      cubit.toggle('n-2');

      expect(cubit.state.jumlah(PilihFilter.semua), 4);
      expect(cubit.state.jumlah(PilihFilter.terpilih), 2);
      expect(cubit.state.jumlah(PilihFilter.belumDipilih), 2);
      expect(cubit.state.jumlah(PilihFilter.saldoKosong), 1);
    });
  });

  group('picking what is shown', () {
    test('the checkbox picks everyone shown who has saldo', () {
      cubit.pilihTampil();

      expect(cubit.state.selectedIds, {'n-1', 'n-2', 'n-3'});
      expect(cubit.state.pilihanTampil, PilihanTampil.semua);
    });

    test('it picks only what a filter leaves on screen', () {
      cubit.setSaldoMin(200000);

      cubit.pilihTampil();

      expect(cubit.state.selectedIds, {'n-1', 'n-3'});
    });

    test('when all are picked, it un-picks them again', () {
      cubit.pilihTampil();

      cubit.pilihTampil();

      expect(cubit.state.selectedIds, isEmpty);
      expect(cubit.state.pilihanTampil, PilihanTampil.tidakAda);
    });

    test('some picked reads as partial, and picks the rest', () {
      cubit.toggle('n-1');
      expect(cubit.state.pilihanTampil, PilihanTampil.sebagian);

      cubit.pilihTampil();

      expect(cubit.state.selectedIds, {'n-1', 'n-2', 'n-3'});
    });

    test('un-picking leaves the picks hidden by a filter alone', () {
      cubit.pilihTampil();
      cubit.setSaldoMin(200000);

      cubit.pilihTampil();

      expect(cubit.state.selectedIds, {'n-2'});
    });

    test('invert flips the picks within what is shown, never the empty ones',
        () {
      cubit.toggle('n-1');

      cubit.balikkan();

      expect(cubit.state.selectedIds, {'n-2', 'n-3'});
    });

    test('clear drops every pick, even hidden ones', () {
      cubit.toggle('n-1');
      cubit.toggle('n-2');
      cubit.setFilter(PilihFilter.saldoKosong);

      cubit.kosongkan();

      expect(cubit.state.selectedIds, isEmpty);
      expect(cubit.state.saldoTerpilih, 0);
    });
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
          termasukKosong: true,
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
          termasukKosong: true,
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
