import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_bottom_sheet.dart';

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

  testWidgets('opened cold, the picker fetches every active nasabah',
      (tester) async {
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Right(HalamanNasabah(
        items: [_nasabah('NAS-0001')],
        totalCount: 1,
        hasMore: false,
      )),
    );

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<NasabahCubit>.value(
        value: cubit,
        child: const Scaffold(body: PilihNasabahBottomSheet()),
      ),
    ));
    await tester.pumpAndSettle();

    // Picker tidak boleh memakai jalur berpaginasi milik halaman nasabah,
    // karena ia harus menampilkan seluruh pilihan sekaligus.
    verify(() => getActiveUseCase.execute()).called(1);
    verifyNever(() => getUseCase.execute(any()));
  });

  testWidgets('fetches even when the cubit already holds the nasabah page list',
      (tester) async {
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(HalamanNasabah(
        items: [_nasabah('NAS-0009')],
        totalCount: 1,
        hasMore: false,
      )),
    );
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Right(HalamanNasabah(
        items: [_nasabah('NAS-0001')],
        totalCount: 1,
        hasMore: false,
      )),
    );

    // Pengurus membuka halaman nasabah lebih dulu: cubit sudah Loaded, tetapi
    // daftar picker masih kosong karena diisi jalur yang berbeda.
    await cubit.loadNasabah();
    clearInteractions(getActiveUseCase);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<NasabahCubit>.value(
        value: cubit,
        child: const Scaffold(body: PilihNasabahBottomSheet()),
      ),
    ));
    await tester.pumpAndSettle();

    verify(() => getActiveUseCase.execute()).called(1);
    expect(find.text('Nasabah NAS-0001'), findsOneWidget);
  });
}
