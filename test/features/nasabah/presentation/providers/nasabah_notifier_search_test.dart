import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:pilah_mobile/core/bases/request_cancellation.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
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
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import '../../../../support/mock_sinkron_profil_nasabah_use_case.dart';
import '../../../../support/notifier_harness.dart';

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
  late NasabahNotifier cubit;
  late NotifierHarness<NasabahNotifier, NasabahState> harness;
  late _MockGetNasabahUseCase getUseCase;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    harness = NotifierHarness(
      nasabahProvider,
      () => NasabahNotifier(
        getUseCase,
        _MockGetActiveNasabahUseCase(),
        _MockGetNasabahRingkasanUseCase(),
        _MockAddNasabahUseCase(),
        _MockUpdateNasabahUseCase(),
        _MockActivateNasabahUseCase(),
        _MockDeactivateNasabahUseCase(),
        _MockApproveNasabahUseCase(),
        _MockRejectNasabahUseCase(),
        MockSinkronProfilNasabahUseCase(),
      ),
    );
    cubit = harness.notifier;
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(
          _page([_nasabah('Budi Santoso', 'budi@example.com', '81234567890')])),
    );
  });

  tearDown(() => harness.dispose());

  test('logout cancels an active-count refresh after a mutation', () async {
    await cubit.setActiveTab(false);
    when(() => cubit.activateNasabahUseCase.execute(any()))
        .thenAnswer((_) async => const Right(null));
    final countResponse = Completer<Either<NetworkException, HalamanNasabah>>();
    final countStarted = Completer<void>();
    RequestCancellation? countCancellation;
    when(() => getUseCase.execute(any())).thenAnswer((call) {
      final params = call.positionalArguments.first as GetNasabahParams;
      if (params.status == 'aktif' && params.pageSize == 1) {
        countCancellation = params.cancellation;
        countStarted.complete();
        return countResponse.future;
      }
      return Future.value(Right(_page([])));
    });
    final mutation = cubit.setNasabahStatus('n-1', true);
    await countStarted.future;
    cubit.reset();
    final cancelled = countCancellation?.isCancelled ?? false;
    countResponse.complete(Left(RequestCancelled()));
    await mutation;
    expect(cancelled, isTrue);
    expect(cubit.activeCount, 0);
    expect(cubit.state, isA<NasabahInitial>());
  });

  test('logout reset cancels the request and keeps the initial state',
      () async {
    final response = Completer<Either<NetworkException, HalamanNasabah>>();
    RequestCancellation? token;
    when(() => getUseCase.execute(any())).thenAnswer((call) {
      token = (call.positionalArguments.first as GetNasabahParams).cancellation;
      return response.future;
    });
    final load = cubit.loadNasabah();
    cubit.reset();
    final cancelledAtLogout = token!.isCancelled;
    response.complete(Left(RequestCancelled()));
    await load;
    expect(cancelledAtLogout, isTrue);
    expect(cubit.state, isA<NasabahInitial>());
  });

  test('disposing the provider cancels its in-flight request', () async {
    final response = Completer<Either<NetworkException, HalamanNasabah>>();
    RequestCancellation? token;
    when(() => getUseCase.execute(any())).thenAnswer((call) {
      token = (call.positionalArguments.first as GetNasabahParams).cancellation;
      return response.future;
    });
    final load = cubit.loadNasabah();
    harness.dispose();
    expect(token!.isCancelled, isTrue);
    response.complete(Left(RequestCancelled()));
    await load;
  });

  test('a cancelled latest request never becomes an error state', () async {
    when(() => getUseCase.execute(any()))
        .thenAnswer((_) async => Left(RequestCancelled()));
    await cubit.loadNasabah();
    expect(cubit.state, isA<NasabahInitial>());
  });

  test('a cancelled refresh keeps existing rows and clears the loading flag',
      () async {
    await cubit.loadNasabah();
    when(() => getUseCase.execute(any()))
        .thenAnswer((_) async => Left(RequestCancelled()));
    await cubit.loadNasabah();
    final loaded = cubit.state as NasabahLoaded;
    expect(loaded.nasabahList.single.name, 'Budi Santoso');
    expect(loaded.isReloading, isFalse);
  });

  testWidgets('superseded search cancels transport without displaying an error',
      (tester) async {
    await cubit.loadNasabah();
    final oldResponse = Completer<Either<NetworkException, HalamanNasabah>>();
    RequestCancellation? oldToken;
    when(() => getUseCase.execute(any())).thenAnswer((call) {
      final params = call.positionalArguments.first as GetNasabahParams;
      if (params.search == 'old') {
        oldToken = params.cancellation;
        return oldResponse.future;
      }
      return Future.value(Right(_page([
        _nasabah('Siti Aminah', 'siti@example.test', '81234567890'),
      ])));
    });
    cubit.searchNasabah('old');
    await tester.pump(NasabahNotifier.jedaPencarian);
    expect(oldToken, isNotNull);
    cubit.searchNasabah('new');
    expect(oldToken!.isCancelled, isTrue);
    oldResponse.complete(Left(RequestCancelled()));
    await tester.pump();
    expect(cubit.state, isNot(isA<NasabahError>()));
    await tester.pump(NasabahNotifier.jedaPencarian);
    expect(
        (cubit.state as NasabahLoaded).nasabahList.single.name, 'Siti Aminah');
  });

  testWidgets('trims whitespace before debounce and minimum query length',
      (tester) async {
    await cubit.loadNasabah();
    cubit.searchNasabah('  bu  ');
    await tester.pump(NasabahNotifier.jedaPencarian);
    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.last.search, 'bu');
    expect(cubit.searchQuery, 'bu');
  });

  // Pencarian dijalankan server (PIL-214) supaya seluruh nasabah ikut dicari,
  // bukan hanya halaman yang kebetulan sudah dimuat. Backend mencocokkan nama,
  // ID nasabah, nomor HP, dan email sekaligus.
  test('forwards the typed query to the server after the typing pause',
      () async {
    await cubit.loadNasabah();

    cubit.searchNasabah('budi@example.com');
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

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
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

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
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

    verify(() => getUseCase.execute(any())).called(1);
  });

  test('sends a two-character query, the shortest the server will honour',
      () async {
    await cubit.loadNasabah();

    // Batas persis: satu huruf diabaikan server, dua huruf sudah dilayani.
    cubit.searchNasabah('bu');
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.last.search, 'bu');
  });

  test('clearing the query drops it from the request', () async {
    await cubit.loadNasabah();

    cubit.searchNasabah('budi');
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);
    cubit.searchNasabah('');
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.last.search, isNull);
  });
}
