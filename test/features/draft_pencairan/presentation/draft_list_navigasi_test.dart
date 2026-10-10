import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_state.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/draft_format.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

DraftRingkasan _draft(
  String id,
  String nama, {
  DraftStatus status = DraftStatus.draft,
  String pembuat = 'Ibu Sari',
  DateTime? dibuat,
  int dibayar = 100000,
}) =>
    DraftRingkasan(
      id: id,
      nama: nama,
      status: status,
      dibuatOlehNama: pembuat,
      createdAt: dibuat ?? DateTime(2026, 10, 7, 9, 5),
      jumlahItem: 1,
      totalNominal: dibayar,
      totalPotongan: 0,
      totalDibayar: dibayar,
    );

void main() {
  late _MockUseCases useCases;
  late DraftListCubit cubit;

  final rows = [
    _draft('d-1', 'Cair Oktober',
        dibuat: DateTime(2026, 10, 7, 9, 5), dibayar: 300000),
    _draft('d-2', 'Cair September',
        status: DraftStatus.dikonfirmasi,
        pembuat: 'Pak Budi',
        dibuat: DateTime(2026, 9, 20, 8, 0),
        dibayar: 100000),
    _draft('d-3', 'Bayar Akhir',
        status: DraftStatus.dibatalkan,
        dibuat: DateTime(2026, 10, 9, 14, 30),
        dibayar: 200000),
  ];

  setUp(() async {
    useCases = _MockUseCases();
    cubit = DraftListCubit(useCases);
    when(() => useCases.getDrafts()).thenAnswer((_) async => Right(rows));
    await cubit.load();
  });

  group('searching', () {
    test('matches the name, whatever the case', () {
      cubit.setQuery('SEPTEMBER');
      expect(cubit.state.tampil.map((d) => d.id), ['d-2']);
    });

    test('matches who made it', () {
      cubit.setQuery('budi');
      expect(cubit.state.tampil.map((d) => d.id), ['d-2']);
    });

    test('matches the date as written on the card', () {
      cubit.setQuery('7 okt');
      expect(cubit.state.tampil.map((d) => d.id), ['d-1']);
    });

    test('ignores blanks around the words, and clearing shows all', () {
      cubit.setQuery('  cair  ');
      expect(cubit.state.tampil, hasLength(2));
      cubit.setQuery('');
      expect(cubit.state.tampil, hasLength(3));
    });

    test('narrows together with the status filter', () {
      cubit.setQuery('cair');
      cubit.setFilter(DraftStatus.draft);
      expect(cubit.state.tampil.map((d) => d.id), ['d-1']);
    });
  });

  group('counts on the chips', () {
    test('count every status, and all of them for null', () {
      expect(cubit.state.jumlah(null), 3);
      expect(cubit.state.jumlah(DraftStatus.draft), 1);
      expect(cubit.state.jumlah(DraftStatus.dikonfirmasi), 1);
      expect(cubit.state.jumlah(DraftStatus.dibatalkan), 1);
    });

    test('follow the search but not the chosen status', () {
      cubit.setFilter(DraftStatus.draft);
      cubit.setQuery('cair');
      expect(cubit.state.jumlah(null), 2);
      expect(cubit.state.jumlah(DraftStatus.dikonfirmasi), 1);
      expect(cubit.state.jumlah(DraftStatus.dibatalkan), 0);
    });
  });

  group('sorting', () {
    test('newest first by default', () {
      expect(cubit.state.urutan.field, DraftSortField.tanggal);
      expect(cubit.state.urutan.ascending, isFalse);
      expect(cubit.state.tampil.map((d) => d.id), ['d-3', 'd-1', 'd-2']);
    });

    test('choosing the date again flips it to oldest first', () {
      cubit.setUrutan(DraftSortField.tanggal);
      expect(cubit.state.urutan.ascending, isTrue);
      expect(cubit.state.tampil.map((d) => d.id), ['d-2', 'd-1', 'd-3']);
    });

    test('the total paid starts with the biggest, and flips to the smallest',
        () {
      cubit.setUrutan(DraftSortField.dibayar);
      expect(cubit.state.urutan.ascending, isFalse);
      expect(cubit.state.tampil.map((d) => d.id), ['d-1', 'd-3', 'd-2']);
      cubit.setUrutan(DraftSortField.dibayar);
      expect(cubit.state.tampil.map((d) => d.id), ['d-2', 'd-3', 'd-1']);
    });

    test('a name goes A to Z first', () {
      cubit.setUrutan(DraftSortField.nama);
      expect(cubit.state.urutan.ascending, isTrue);
      expect(cubit.state.tampil.map((d) => d.id), ['d-3', 'd-1', 'd-2']);
      cubit.setUrutan(DraftSortField.nama);
      expect(cubit.state.tampil.map((d) => d.id), ['d-2', 'd-1', 'd-3']);
    });

    test('only the date order is grouped under date headings', () {
      expect(const DraftSort.awal().perTanggal, isTrue);
      expect(const DraftSort(DraftSortField.tanggal, true).perTanggal, isTrue);
      expect(
          const DraftSort(DraftSortField.dibayar, false).perTanggal, isFalse);
      expect(const DraftSort(DraftSortField.nama, true).perTanggal, isFalse);
    });
  });

  group('date group headings', () {
    final sekarang = DateTime(2026, 10, 10, 9, 30);

    test('today, yesterday, this week, then month and year', () {
      expect(labelKelompok(DateTime(2026, 10, 10, 1), sekarang: sekarang),
          'HARI INI');
      expect(labelKelompok(DateTime(2026, 10, 9, 23), sekarang: sekarang),
          'KEMARIN');
      expect(labelKelompok(DateTime(2026, 10, 5, 12), sekarang: sekarang),
          'MINGGU INI');
      expect(labelKelompok(DateTime(2026, 10, 2, 12), sekarang: sekarang),
          'OKTOBER 2026');
      expect(labelKelompok(DateTime(2026, 9, 20), sekarang: sekarang),
          'SEPTEMBER 2026');
    });

    test('an unknown date has its own heading', () {
      expect(labelKelompok(null, sekarang: sekarang), 'TANPA TANGGAL');
    });
  });
}
