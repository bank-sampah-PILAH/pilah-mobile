import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_state.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/pilih_nasabah_provider.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockRepository extends Mock implements DraftPencairanRepository {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);
const _fani =
    Kandidat(id: 'n-4', kode: 'NAS-0004', nama: 'Fani Kosong', saldo: 0);

void main() {
  late _MockRepository repository;
  late ProviderContainer container;
  late PilihNasabahNotifier notifier;

  PilihNasabahState state() => container.read(pilihNasabahProvider);

  void answer({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    required List<Kandidat> rows,
  }) {
    when(() => repository.getKandidat(
          search: search,
          urutan: urutan,
          termasukKosong: true,
        )).thenAnswer((_) async => Right(rows));
  }

  setUp(() async {
    repository = _MockRepository();
    answer(rows: [_ahmad, _budi, _citra, _fani]);
    container = ProviderContainer(overrides: [
      pilihNasabahProvider.overrideWith(
        () => PilihNasabahNotifier(repository),
      ),
    ]);
    addTearDown(container.dispose);
    notifier = container.read(pilihNasabahProvider.notifier);
    await notifier.load();
  });

  test('lists everyone, nasabah without saldo included, none picked yet', () {
    expect(state().status, PilihStatus.loaded);
    expect(state().kandidat, [_ahmad, _budi, _citra, _fani]);
    expect(state().selectedIds, isEmpty);
    expect(state().jumlahTerpilih, 0);
  });

  test('picking and un-picking one nasabah tracks count and saldo', () {
    notifier.toggle('n-1');
    notifier.toggle('n-2');
    notifier.toggle('n-1');

    expect(state().selectedIds, {'n-2'});
    expect(state().jumlahTerpilih, 1);
    expect(state().saldoTerpilih, 50000);
  });

  test('a nasabah without saldo cannot be picked', () {
    notifier.toggle('n-4');
    expect(state().selectedIds, isEmpty);
  });

  test('searching and sorting ask the server, and the picks survive', () async {
    notifier.toggle('n-1');
    answer(search: 'bud', rows: [_budi]);
    await notifier.setSearch('bud');

    expect(state().kandidat, [_budi]);
    expect(state().selectedIds, {'n-1'});
    expect(state().saldoTerpilih, 465600,
        reason: 'a pick hidden by the search still counts');

    answer(search: 'bud', urutan: KandidatUrutan.saldoTerbesar, rows: [_budi]);
    await notifier.setUrutan(KandidatUrutan.saldoTerbesar);

    verify(() => repository.getKandidat(
          search: 'bud',
          urutan: KandidatUrutan.saldoTerbesar,
          termasukKosong: true,
        )).called(1);
  });

  group('sorting by field', () {
    test('name starts A to Z, and again flips to Z to A', () async {
      answer(urutan: KandidatUrutan.namaZA, rows: [_fani, _citra]);
      await notifier.setSortField(KandidatSortField.nama);
      expect(state().urutan, KandidatUrutan.namaZA);
    });

    test('saldo starts with the biggest, and again flips to the smallest',
        () async {
      answer(urutan: KandidatUrutan.saldoTerbesar, rows: [_ahmad]);
      await notifier.setSortField(KandidatSortField.saldo);
      expect(state().urutan, KandidatUrutan.saldoTerbesar);

      answer(urutan: KandidatUrutan.saldoTerkecil, rows: [_fani]);
      await notifier.setSortField(KandidatSortField.saldo);
      expect(state().urutan, KandidatUrutan.saldoTerkecil);
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
      expect(state().tampil, [_ahmad, _budi, _citra, _fani]);
    });

    test('only the picked, or only those not picked yet', () {
      notifier.toggle('n-1');
      notifier.setFilter(PilihFilter.terpilih);
      expect(state().tampil, [_ahmad]);
      notifier.setFilter(PilihFilter.belumDipilih);
      expect(state().tampil, [_budi, _citra, _fani]);
    });

    test('only those without saldo', () {
      notifier.setFilter(PilihFilter.saldoKosong);
      expect(state().tampil, [_fani]);
    });

    test('a minimum saldo narrows the list, and zero clears it', () {
      notifier.setSaldoMin(200000);
      expect(state().tampil, [_ahmad, _citra]);
      notifier.setSaldoMin(0);
      expect(state().tampil, hasLength(4));
    });

    test('a minimum saldo combines with a status filter', () {
      notifier.toggle('n-1');
      notifier.setSaldoMin(200000);
      notifier.setFilter(PilihFilter.belumDipilih);
      expect(state().tampil, [_citra]);
    });

    test('counts say how many each filter holds', () {
      notifier.toggle('n-1');
      notifier.toggle('n-2');
      expect(state().jumlah(PilihFilter.semua), 4);
      expect(state().jumlah(PilihFilter.terpilih), 2);
      expect(state().jumlah(PilihFilter.belumDipilih), 2);
      expect(state().jumlah(PilihFilter.saldoKosong), 1);
    });
  });

  group('picking what is shown', () {
    test('the checkbox picks everyone shown who has saldo', () {
      notifier.pilihTampil();
      expect(state().selectedIds, {'n-1', 'n-2', 'n-3'});
      expect(state().pilihanTampil, PilihanTampil.semua);
    });

    test('it picks only what a filter leaves on screen', () {
      notifier.setSaldoMin(200000);
      notifier.pilihTampil();
      expect(state().selectedIds, {'n-1', 'n-3'});
    });

    test('when all are picked, it un-picks them again', () {
      notifier.pilihTampil();
      notifier.pilihTampil();
      expect(state().selectedIds, isEmpty);
      expect(state().pilihanTampil, PilihanTampil.tidakAda);
    });

    test('some picked reads as partial, and picks the rest', () {
      notifier.toggle('n-1');
      expect(state().pilihanTampil, PilihanTampil.sebagian);
      notifier.pilihTampil();
      expect(state().selectedIds, {'n-1', 'n-2', 'n-3'});
    });

    test('un-picking leaves the picks hidden by a filter alone', () {
      notifier.pilihTampil();
      notifier.setSaldoMin(200000);
      notifier.pilihTampil();
      expect(state().selectedIds, {'n-2'});
    });

    test('invert flips the picks within what is shown, never the empty ones',
        () {
      notifier.toggle('n-1');
      notifier.balikkan();
      expect(state().selectedIds, {'n-2', 'n-3'});
    });

    test('clear drops every pick, even hidden ones', () {
      notifier.toggle('n-1');
      notifier.toggle('n-2');
      notifier.setFilter(PilihFilter.saldoKosong);
      notifier.kosongkan();
      expect(state().selectedIds, isEmpty);
      expect(state().saldoTerpilih, 0);
    });
  });

  test('the picked nasabah come back in name order for the editor', () {
    notifier.toggle('n-3');
    notifier.toggle('n-1');
    expect(state().terpilih, [_ahmad, _citra]);
  });

  test('a failed load says why', () async {
    when(() => repository.getKandidat(
          search: '',
          urutan: KandidatUrutan.namaAZ,
          termasukKosong: true,
        )).thenAnswer((_) async => Left(ConnectionTimeOutException()));

    await notifier.load();

    expect(state().status, PilihStatus.failure);
    expect(state().errorMessage, isNotNull);
  });

  test('a slow answer for an old search never overwrites the newer one',
      () async {
    final slow = Completer<Either<NetworkException, List<Kandidat>>>();
    when(() => repository.getKandidat(
          search: 'a',
          urutan: KandidatUrutan.namaAZ,
          termasukKosong: true,
        )).thenAnswer((_) => slow.future);
    answer(search: 'ab', rows: [_ahmad]);

    final first = notifier.setSearch('a');
    await notifier.setSearch('ab');
    slow.complete(Right([_budi, _citra]));
    await first;

    expect(state().kandidat, [_ahmad]);
    expect(state().search, 'ab');
  });

  test('ignores an in-flight search after disposal', () async {
    final slow = Completer<Either<NetworkException, List<Kandidat>>>();
    when(() => repository.getKandidat(
          search: 'pending',
          urutan: KandidatUrutan.namaAZ,
          termasukKosong: true,
        )).thenAnswer((_) => slow.future);
    final inFlight = notifier.setSearch('pending');

    container.dispose();
    slow.complete(const Right([_ahmad]));
    await expectLater(inFlight, completes);
  });

  test('resolves its repository from DI', () async {
    di.registerSingleton<DraftPencairanRepository>(repository);
    addTearDown(() => di.unregister<DraftPencairanRepository>());
    final diContainer = ProviderContainer();
    addTearDown(diContainer.dispose);
    clearInteractions(repository);

    await diContainer.read(pilihNasabahProvider.notifier).load();

    verify(() => repository.getKandidat(
          search: '',
          urutan: KandidatUrutan.namaAZ,
          termasukKosong: true,
        )).called(1);
  });
}
