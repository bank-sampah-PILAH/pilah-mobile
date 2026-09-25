import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
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

/// Bungkus daftar nasabah menjadi satu halaman utuh (tanpa halaman lanjutan).
HalamanNasabah _page(List<NasabahEntity> items) =>
    HalamanNasabah(items: items, totalCount: items.length, hasMore: false);

void main() {
  late NasabahCubit cubit;
  late _MockGetNasabahUseCase getUseCase;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    cubit = NasabahCubit(
      getUseCase,
      _MockGetActiveNasabahUseCase(),
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
    );
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(
          _page([_nasabah('Budi Santoso', 'budi@example.com', '81234567890')])),
    );
  });

  // Pencarian dijalankan server (PIL-214) supaya seluruh nasabah ikut dicari,
  // bukan hanya halaman yang kebetulan sudah dimuat. Backend mencocokkan nama,
  // nomor HP, dan email sekaligus.
  test('forwards the typed query to the server after the typing pause',
      () async {
    await cubit.loadNasabah();

    cubit.searchNasabah('budi@example.com');
    await Future<void>.delayed(NasabahCubit.jedaPencarian * 2);

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.last.search, 'budi@example.com');
    expect(params.last.page, 1, reason: 'a new query restarts at page one');
  });

  test('keeps a one-letter query off the wire, matching the server contract',
      () async {
    await cubit.loadNasabah();

    cubit.searchNasabah('b');
    await Future<void>.delayed(NasabahCubit.jedaPencarian * 2);

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.last.search, isNull);
  });

  test('only calls the API once for a burst of keystrokes', () async {
    await cubit.loadNasabah();
    clearInteractions(getUseCase);

    cubit.searchNasabah('b');
    cubit.searchNasabah('bu');
    cubit.searchNasabah('bud');
    cubit.searchNasabah('budi');
    await Future<void>.delayed(NasabahCubit.jedaPencarian * 2);

    verify(() => getUseCase.execute(any())).called(1);
  });
}
