import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockGetNasabahRingkasanUseCase extends Mock
    implements GetNasabahRingkasanUseCase {}

class _MockAddNasabahUseCase extends Mock implements AddNasabahUseCase {}

class _MockUpdateNasabahUseCase extends Mock implements UpdateNasabahUseCase {}

class _MockActivateNasabahUseCase extends Mock
    implements ActivateNasabahUseCase {}

class _MockDeactivateNasabahUseCase extends Mock
    implements DeactivateNasabahUseCase {}

class _MockApproveNasabahUseCase extends Mock
    implements ApproveNasabahUseCase {}

class _MockRejectNasabahUseCase extends Mock implements RejectNasabahUseCase {}

NasabahEntity _nasabah(String name, String email, String phone) =>
    NasabahEntity(
      id: 'n-1',
      idNasabah: 'NAS-0900',
      name: name,
      email: email,
      phone: phone,
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati No. 3',
      initials: 'BS',
      avatarColor: Colors.blue,
      textColor: Colors.white,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/2000',
    );

void main() {
  late NasabahCubit cubit;
  late _MockGetNasabahUseCase getUseCase;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    cubit = NasabahCubit(
      getUseCase,
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
    );
    when(() => getUseCase.execute()).thenAnswer(
      (_) async =>
          Right([_nasabah('Budi Santoso', 'budi@example.com', '81234567890')]),
    );
  });

  test('search matches nasabah by email, same as name and phone', () async {
    await cubit.loadNasabah();

    cubit.searchNasabah('budi@example.com');
    expect(
      (cubit.state as NasabahLoaded).nasabahList,
      hasLength(1),
      reason: 'email typed into search should find the nasabah',
    );

    cubit.searchNasabah('siti@example.com');
    expect((cubit.state as NasabahLoaded).nasabahList, isEmpty);

    cubit.searchNasabah('Budi');
    expect((cubit.state as NasabahLoaded).nasabahList, hasLength(1));
  });
}
