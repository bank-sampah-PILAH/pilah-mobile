import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
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
import '../../../../support/mock_sinkron_profil_nasabah_use_case.dart';

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

HalamanNasabah _page(
  List<NasabahEntity> items, {
  int? totalCount,
  bool hasMore = false,
}) =>
    HalamanNasabah(
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
      MockSinkronProfilNasabahUseCase(),
    );
  });

  tearDown(() => cubit.close());

  test('picker fetch leaves the nasabah page state intact', () async {
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(_page([_nasabah('NAS-0009')])),
    );
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Right(_page([_nasabah('NAS-0001'), _nasabah('NAS-0002')])),
    );

    await cubit.loadNasabah();
    final pageState = cubit.state;
    clearInteractions(getUseCase);
    await cubit.loadActiveNasabah();

    expect(cubit.state, same(pageState));
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

  test('appends the next page instead of replacing the visible rows', () async {
    when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      return Right(params.page == 1
          ? _page([_nasabah('NAS-0001')], totalCount: 3, hasMore: true)
          : _page([_nasabah('NAS-0002'), _nasabah('NAS-0003')],
              totalCount: 3, hasMore: false));
    });

    await cubit.loadNasabah();
    await cubit.loadMoreNasabah();

    final state = cubit.state as NasabahLoaded;
    expect(state.nasabahList.map((n) => n.idNasabah),
        ['NAS-0001', 'NAS-0002', 'NAS-0003']);
    expect(state.hasMore, isFalse);
  });

  test('a late response from the previous tab cannot replace the new tab',
      () async {
    final activeResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    when(() => getUseCase.execute(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      if (params.status == 'aktif') return activeResponse.future;
      return Future.value(Right(_page([_nasabah('NAS-INACTIVE')])));
    });

    final activeLoad = cubit.loadNasabah();
    await cubit.setActiveTab(false);
    activeResponse.complete(Right(_page([_nasabah('NAS-ACTIVE')])));
    await activeLoad;

    final state = cubit.state as NasabahLoaded;
    expect(state.isActiveTab, isFalse);
    expect(state.nasabahList.map((n) => n.idNasabah), ['NAS-INACTIVE']);
  });

  test('a late next-page response cannot append rows after switching tabs',
      () async {
    final nextPageResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    when(() => getUseCase.execute(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      if (params.status == 'aktif' && params.page == 2) {
        return nextPageResponse.future;
      }
      if (params.status == 'aktif') {
        return Future.value(
            Right(_page([_nasabah('NAS-ACTIVE-1')], hasMore: true)));
      }
      return Future.value(Right(_page([_nasabah('NAS-INACTIVE')])));
    });

    await cubit.loadNasabah();
    final nextPageLoad = cubit.loadMoreNasabah();
    await cubit.setActiveTab(false);
    nextPageResponse.complete(Right(_page([_nasabah('NAS-ACTIVE-2')])));
    await nextPageLoad;

    final state = cubit.state as NasabahLoaded;
    expect(state.isActiveTab, isFalse);
    expect(state.nasabahList.map((n) => n.idNasabah), ['NAS-INACTIVE']);
  });

  test('a late next-page response cannot append rows after searching',
      () async {
    final nextPageResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    when(() => getUseCase.execute(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      if (params.page == 2) return nextPageResponse.future;
      if (params.search == 'Bu') {
        return Future.value(Right(_page([_nasabah('NAS-BUDI')])));
      }
      return Future.value(
          Right(_page([_nasabah('NAS-ACTIVE-1')], hasMore: true)));
    });

    await cubit.loadNasabah();
    final nextPageLoad = cubit.loadMoreNasabah();
    cubit.searchNasabah('Bu');
    await Future<void>.delayed(
        NasabahCubit.jedaPencarian + const Duration(milliseconds: 50));
    nextPageResponse.complete(Right(_page([_nasabah('NAS-ACTIVE-2')])));
    await nextPageLoad;

    final state = cubit.state as NasabahLoaded;
    expect(state.searchQuery, 'Bu');
    expect(state.nasabahList.map((n) => n.idNasabah), ['NAS-BUDI']);
  });

  test('stays quiet once the last page has been reached', () async {
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(_page([_nasabah('NAS-0001')])),
    );

    await cubit.loadNasabah();
    clearInteractions(getUseCase);
    await cubit.loadMoreNasabah();

    verifyNever(() => getUseCase.execute(any()));
  });

  test('ignores a second request while one page is already in flight',
      () async {
    when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      if (params.page > 1) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return Right(_page([_nasabah('NAS-000${params.page}')], hasMore: true));
    });

    await cubit.loadNasabah();
    clearInteractions(getUseCase);

    // Menggulir cepat memanggil ini berkali-kali; hanya satu yang boleh jalan.
    await Future.wait([
      cubit.loadMoreNasabah(),
      cubit.loadMoreNasabah(),
      cubit.loadMoreNasabah(),
    ]);

    verify(() => getUseCase.execute(any())).called(1);
  });

  test('keeps the rows on screen when loading the next page fails', () async {
    var panggilan = 0;
    when(() => getUseCase.execute(any())).thenAnswer((_) async {
      panggilan++;
      if (panggilan == 1) {
        return Right(_page([_nasabah('NAS-0001')], hasMore: true));
      }
      return Left(NetworkException(message: 'jaringan putus'));
    });

    await cubit.loadNasabah();
    await cubit.loadMoreNasabah();

    final state = cubit.state as NasabahLoaded;
    expect(state.nasabahList.map((n) => n.idNasabah), ['NAS-0001']);
    expect(state.isLoadingMore, isFalse);
  });

  test('surfaces an error when the picker list cannot be fetched', () async {
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Left(NetworkException(message: 'jaringan putus')),
    );

    await expectLater(
      cubit.loadActiveNasabah(),
      throwsA(isA<NetworkException>()),
    );

    expect(cubit.state, isA<NasabahInitial>());
    expect(cubit.activeNasabah, isEmpty);
  });
}
