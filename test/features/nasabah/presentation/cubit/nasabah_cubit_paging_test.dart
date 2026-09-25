import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockGetActiveNasabahUseCase extends Mock
    implements GetActiveNasabahUseCase {}

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

NasabahEntity _nasabah(String nomor) => NasabahEntity(
      id: nomor,
      idNasabah: nomor,
      name: 'Nasabah $nomor',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

NasabahPage _page(
  List<NasabahEntity> items, {
  int? totalCount,
  bool hasMore = false,
}) =>
    NasabahPage(
      items: items,
      totalCount: totalCount ?? items.length,
      hasMore: hasMore,
    );

void main() {
  late _MockGetNasabahUseCase getUseCase;
  late _MockGetActiveNasabahUseCase getActiveUseCase;
  late NasabahCubit cubit;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    getActiveUseCase = _MockGetActiveNasabahUseCase();
    cubit = NasabahCubit(
      getUseCase,
      getActiveUseCase,
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
    );
  });

  tearDown(() => cubit.close());

  test('picker list comes from its own fetch, not the paged page list',
      () async {
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Right(_page([_nasabah('NAS-0001'), _nasabah('NAS-0002')])),
    );

    await cubit.loadActiveNasabah();

    expect(
      cubit.activeNasabah.map((n) => n.idNasabah),
      ['NAS-0001', 'NAS-0002'],
    );
    verifyNever(() => getUseCase.execute(any()));
  });

  test('switching tab asks the server for that tab, from the first page',
      () async {
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(_page([_nasabah('NAS-0001')])),
    );

    await cubit.loadNasabah();
    await cubit.setActiveTab(false);

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.first.status, 'aktif');
    expect(params.last.status, 'tidak_aktif');
    expect(params.last.page, 1);
  });
}
