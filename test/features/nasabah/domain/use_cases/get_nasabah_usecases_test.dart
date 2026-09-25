import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';

class _MockRepository extends Mock implements NasabahRepository {}

void main() {
  late _MockRepository repository;

  const halaman = HalamanNasabah(items: [], totalCount: 7, hasMore: false);

  setUp(() {
    repository = _MockRepository();
    when(() => repository.getNasabah(
          page: any(named: 'page'),
          status: any(named: 'status'),
          search: any(named: 'search'),
        )).thenAnswer((_) async => const Right(halaman));
    when(() => repository.getActiveNasabah())
        .thenAnswer((_) async => const Right(halaman));
  });

  test('GetNasabahUseCase hands the params to the repository', () async {
    await GetNasabahUseCase(repository).execute(
      const GetNasabahParams(page: 4, status: 'ditolak', search: 'siti'),
    );

    verify(() => repository.getNasabah(
        page: 4, status: 'ditolak', search: 'siti')).called(1);
  });

  test('GetNasabahUseCase falls back to the first aktif page without params',
      () async {
    // Dipanggil tanpa argumen oleh kode lama; jangan sampai meledak.
    await GetNasabahUseCase(repository).execute();

    verify(() => repository.getNasabah(page: 1, status: 'aktif', search: null))
        .called(1);
  });

  test('GetActiveNasabahUseCase asks the repository for the picker list',
      () async {
    final hasil = await GetActiveNasabahUseCase(repository).execute();

    expect(hasil.isRight(), isTrue);
    verify(() => repository.getActiveNasabah()).called(1);
  });
}
