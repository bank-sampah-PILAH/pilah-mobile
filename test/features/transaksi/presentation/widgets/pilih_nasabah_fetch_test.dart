import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_picker.dart';
import '../../../../support/notifier_harness.dart';
import '../../../../support/mock_sinkron_profil_nasabah_use_case.dart';
import '../../../../support/nasabah_support.dart';

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
  late NasabahNotifier notifier;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    getActiveUseCase = _MockGetActiveNasabahUseCase();
    notifier = NasabahNotifier(
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

  testWidgets('opened cold, the picker fetches its first active page', (
    tester,
  ) async {
    when(() => getUseCase.execute(any())).thenAnswer(
      (_) async => Right(
        HalamanNasabah(
          items: [_nasabah('NAS-0001')],
          totalCount: 1,
          hasMore: false,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: withNasabahProvider(
          notifier,
          const Scaffold(body: PilihNasabahPicker()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .single as GetNasabahParams;
    expect(params.page, 1);
    expect(params.pageSize, 50);
    expect(params.status, 'aktif');
    expect(params.search, isNull);
    verifyNever(() => getActiveUseCase.execute());
  });

  testWidgets(
    'fetches even when the notifier already holds the nasabah page list',
    (tester) async {
      when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single as GetNasabahParams;
        final id = params.pageSize == null ? 'NAS-0009' : 'NAS-0001';
        return Right(
          HalamanNasabah(items: [_nasabah(id)], totalCount: 1, hasMore: false),
        );
      });

      // The page state is loaded first in the same container the picker uses.
      final harness = NotifierHarness(nasabahProvider, () => notifier);
      addTearDown(harness.dispose);
      await notifier.loadNasabah();
      final pageState = notifier.state;
      clearInteractions(getUseCase);

      await tester.pumpWidget(
        MaterialApp(
          home: UncontrolledProviderScope(
            container: harness.container,
            child: const Scaffold(body: PilihNasabahPicker()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => getUseCase.execute(any())).called(1);
      verifyNever(() => getActiveUseCase.execute());
      expect(notifier.state, same(pageState));
      expect(find.text('Nasabah NAS-0001'), findsOneWidget);
    },
  );
}
