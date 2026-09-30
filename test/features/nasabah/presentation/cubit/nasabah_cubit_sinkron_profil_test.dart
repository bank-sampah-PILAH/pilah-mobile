import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockSinkronProfilNasabahUseCase extends Mock
    implements SinkronProfilNasabahUseCase {}

class _MockGetActive extends Mock implements GetActiveNasabahUseCase {}

class _MockRingkasan extends Mock implements GetNasabahRingkasanUseCase {}

class _MockAdd extends Mock implements AddNasabahUseCase {}

class _MockUpdate extends Mock implements UpdateNasabahUseCase {}

class _MockActivate extends Mock implements ActivateNasabahUseCase {}

class _MockDeactivate extends Mock implements DeactivateNasabahUseCase {}

class _MockApprove extends Mock implements ApproveNasabahUseCase {}

class _MockReject extends Mock implements RejectNasabahUseCase {}

HalamanNasabah _kosong() =>
    const HalamanNasabah(items: [], totalCount: 0, hasMore: false);

void main() {
  late _MockGetNasabahUseCase getUseCase;
  late _MockSinkronProfilNasabahUseCase sinkronUseCase;
  late NasabahCubit cubit;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    sinkronUseCase = _MockSinkronProfilNasabahUseCase();
    when(() => getUseCase.execute(any()))
        .thenAnswer((_) async => Right(_kosong()));
    cubit = NasabahCubit(
      getUseCase,
      _MockGetActive(),
      _MockRingkasan(),
      _MockAdd(),
      _MockUpdate(),
      _MockActivate(),
      _MockDeactivate(),
      _MockApprove(),
      _MockReject(),
      sinkronUseCase,
    );
  });

  tearDown(() => cubit.close());

  group('sinkronProfil', () {
    test('mengembalikan null dan memuat ulang daftar saat berhasil', () async {
      when(() => sinkronUseCase.execute('nasabah-1'))
          .thenAnswer((_) async => const Right(null));

      final error = await cubit.sinkronProfil('nasabah-1');

      expect(error, isNull);
      verify(() => sinkronUseCase.execute('nasabah-1')).called(1);
      verify(() => getUseCase.execute(any())).called(greaterThanOrEqualTo(1));
    });

    test('mengembalikan galatnya dan tidak memuat ulang saat ditolak',
        () async {
      final failure = NetworkException.handleBadResponse(null);
      when(() => sinkronUseCase.execute('nasabah-1'))
          .thenAnswer((_) async => Left(failure));

      final error = await cubit.sinkronProfil('nasabah-1');

      expect(error, same(failure));
      verifyNever(() => getUseCase.execute(any()));
    });
  });
}
