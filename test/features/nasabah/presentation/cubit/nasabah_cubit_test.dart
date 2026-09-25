import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
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
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class MockGetActiveNasabahUseCase extends Mock
    implements GetActiveNasabahUseCase {}

class MockGetNasabahRingkasanUseCase extends Mock
    implements GetNasabahRingkasanUseCase {}

class MockAddNasabahUseCase extends Mock implements AddNasabahUseCase {}

class MockUpdateNasabahUseCase extends Mock implements UpdateNasabahUseCase {}

class MockActivateNasabahUseCase extends Mock
    implements ActivateNasabahUseCase {}

class MockDeactivateNasabahUseCase extends Mock
    implements DeactivateNasabahUseCase {}

class MockApproveNasabahUseCase extends Mock implements ApproveNasabahUseCase {}

class MockRejectNasabahUseCase extends Mock implements RejectNasabahUseCase {}

NasabahEntity _nasabah(String kode,
        {required String status, bool isActive = true}) =>
    NasabahEntity(
      id: kode,
      idNasabah: kode,
      name: 'Nasabah $kode',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: isActive,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: status,
    );

/// Bungkus daftar nasabah menjadi satu halaman utuh (tanpa halaman lanjutan).
NasabahPage _page(List<NasabahEntity> items) =>
    NasabahPage(items: items, totalCount: items.length, hasMore: false);

void main() {
  late MockGetNasabahUseCase getUseCase;
  late MockGetNasabahRingkasanUseCase ringkasanUseCase;
  late MockAddNasabahUseCase addUseCase;
  late MockUpdateNasabahUseCase updateUseCase;
  late MockActivateNasabahUseCase activateUseCase;
  late MockDeactivateNasabahUseCase deactivateUseCase;
  late MockApproveNasabahUseCase approveUseCase;
  late MockRejectNasabahUseCase rejectUseCase;
  late NasabahCubit cubit;

  setUpAll(() {
    registerFallbackValue(NasabahRequest(
      kode: 'NAS-0001',
      nama: 'Budi',
      email: 'budi@example.com',
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      noHp: '08123456789',
      alamat: 'Jl. Melati',
    ));
    registerFallbackValue(UpdateNasabahParams(
      id: 'x',
      request: NasabahRequest(
        kode: 'NAS-0001',
        nama: 'Budi',
        email: 'budi@example.com',
        jenisKelamin: 'Laki-laki',
        tanggalLahir: '01/01/1990',
        noHp: '08123456789',
        alamat: 'Jl. Melati',
      ),
    ));
    registerFallbackValue(DecideNasabahParams(id: 'x'));
  });

  setUp(() {
    getUseCase = MockGetNasabahUseCase();
    ringkasanUseCase = MockGetNasabahRingkasanUseCase();
    addUseCase = MockAddNasabahUseCase();
    updateUseCase = MockUpdateNasabahUseCase();
    activateUseCase = MockActivateNasabahUseCase();
    deactivateUseCase = MockDeactivateNasabahUseCase();
    approveUseCase = MockApproveNasabahUseCase();
    rejectUseCase = MockRejectNasabahUseCase();
    when(() => getUseCase.execute())
        .thenAnswer((_) async => Right(_page(const [])));
    cubit = NasabahCubit(
      getUseCase,
      MockGetActiveNasabahUseCase(),
      ringkasanUseCase,
      addUseCase,
      updateUseCase,
      activateUseCase,
      deactivateUseCase,
      approveUseCase,
      rejectUseCase,
    );
  });

  List<NasabahEntity> seedData() => [
        _nasabah('NAS-0001', status: 'approved'),
        _nasabah('NAS-0002', status: 'approved', isActive: false),
        _nasabah('NAS-0003', status: 'pending'),
        _nasabah('NAS-0004', status: 'rejected', isActive: false),
      ];

  group('tab filtering', () {
    blocTest<NasabahCubit, NasabahState>(
      'aktif tab shows approved+active only',
      build: () {
        when(() => getUseCase.execute())
            .thenAnswer((_) async => Right(_page(seedData())));
        return cubit;
      },
      act: (cubit) async {
        await cubit.loadNasabah();
        cubit.setActiveTab(true);
      },
      expect: () => [
        isA<NasabahLoading>(),
        isA<NasabahLoaded>().having(
            (s) => s.nasabahList.map((n) => n.idNasabah), 'aktif ids', [
          'NAS-0001'
        ]).having((s) => s.isMenungguTab, 'isMenungguTab', isFalse),
      ],
    );

    blocTest<NasabahCubit, NasabahState>(
      'menunggu tab shows pending rows only',
      build: () {
        when(() => getUseCase.execute())
            .thenAnswer((_) async => Right(_page(seedData())));
        return cubit;
      },
      act: (cubit) async {
        await cubit.loadNasabah();
        cubit.setActiveTab(null);
      },
      expect: () => [
        isA<NasabahLoading>(),
        isA<NasabahLoaded>().having(
            (s) => s.nasabahList.map((n) => n.idNasabah),
            'aktif ids',
            ['NAS-0001']),
        isA<NasabahLoaded>().having(
            (s) => s.nasabahList.map((n) => n.idNasabah), 'menunggu', [
          'NAS-0003'
        ]).having((s) => s.isMenungguTab, 'isMenungguTab', isTrue),
      ],
    );

    test('rejected rows appear in no tab', () async {
      when(() => getUseCase.execute())
          .thenAnswer((_) async => Right(_page(seedData())));
      await cubit.loadNasabah();
      cubit.setActiveTab(true);
      expect((cubit.state as NasabahLoaded).nasabahList.map((n) => n.idNasabah),
          ['NAS-0001']);
      cubit.setActiveTab(false);
      expect((cubit.state as NasabahLoaded).nasabahList.map((n) => n.idNasabah),
          ['NAS-0002']);
      cubit.setActiveTab(null);
      expect((cubit.state as NasabahLoaded).nasabahList.map((n) => n.idNasabah),
          ['NAS-0003']);
    });
  });

  group('activeCount', () {
    test('counts approved active rows only', () async {
      when(() => getUseCase.execute())
          .thenAnswer((_) async => Right(_page(seedData())));
      await cubit.loadNasabah();
      expect(cubit.activeCount, 1);
    });
  });

  group('decideNasabah', () {
    test('approve calls approve use case with catatan and reloads', () async {
      when(() => getUseCase.execute()).thenAnswer((_) async {
        return Right(_page([
          _nasabah('NAS-0003', status: 'approved'),
        ]));
      });
      when(() => approveUseCase.execute(any(that: isA<DecideNasabahParams>())))
          .thenAnswer((_) async => const Right(null));

      final error = await cubit.decideNasabah('NAS-0003',
          approve: true, catatan: 'Data lengkap');

      expect(error, isNull);
      final captured = verify(
              () => approveUseCase.execute(captureAny<DecideNasabahParams>()))
          .captured
          .cast<DecideNasabahParams>()
          .single;
      expect(captured.id, 'NAS-0003');
      expect(captured.catatan, 'Data lengkap');
      verify(() => getUseCase.execute()).called(1);
    });

    test('reject calls reject use case with alasan', () async {
      when(() => getUseCase.execute())
        .thenAnswer((_) async => Right(_page(const [])));
      when(() => rejectUseCase.execute(any(that: isA<DecideNasabahParams>())))
          .thenAnswer((_) async => const Right(null));

      final error = await cubit.decideNasabah('NAS-0003',
          approve: false, catatan: 'Tidak valid');

      expect(error, isNull);
      final captured =
          verify(() => rejectUseCase.execute(captureAny<DecideNasabahParams>()))
              .captured
              .cast<DecideNasabahParams>()
              .single;
      expect(captured.catatan, 'Tidak valid');
    });

    test('returns the failure when the call errors', () async {
      final failure = NetworkException.handleBadResponse(null);
      when(() => approveUseCase.execute(any(that: isA<DecideNasabahParams>())))
          .thenAnswer((_) async => Left(failure));

      final error = await cubit.decideNasabah('NAS-0003', approve: true);
      expect(error, same(failure));
    });
  });
}
