import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

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

/// Bungkus daftar nasabah menjadi satu halaman utuh (tanpa halaman lanjutan).
NasabahPage _page(List<NasabahEntity> items) =>
    NasabahPage(items: items, totalCount: items.length, hasMore: false);

void main() {
  late MockGetNasabahUseCase getUseCase;
  late MockApproveNasabahUseCase approveUseCase;
  late MockRejectNasabahUseCase rejectUseCase;
  late NasabahCubit cubit;

  setUpAll(() {
    registerFallbackValue(DecideNasabahParams(id: 'x'));
  });

  setUp(() {
    getUseCase = MockGetNasabahUseCase();
    approveUseCase = MockApproveNasabahUseCase();
    rejectUseCase = MockRejectNasabahUseCase();
    when(() => getUseCase.execute(any()))
        .thenAnswer((_) async => Right(_page(const [])));
    cubit = NasabahCubit(
      getUseCase,
      MockGetActiveNasabahUseCase(),
      MockGetNasabahRingkasanUseCase(),
      MockAddNasabahUseCase(),
      MockUpdateNasabahUseCase(),
      MockActivateNasabahUseCase(),
      MockDeactivateNasabahUseCase(),
      approveUseCase,
      rejectUseCase,
    );
  });

  Widget host() => MaterialApp(
        home: Scaffold(
          body: NasabahListItem(
            isActive: true,
            initials: 'B',
            avatarColor: const Color(0xFFEAF5EC),
            textColor: const Color(0xFF2F6B45),
            name: 'Budi Santoso',
            phone: '08123456789',
            balance: 'Rp 0',
            idNasabah: 'NAS-0001',
            isPending: true,
            nasabahCubit: cubit,
          ),
        ),
      );

  testWidgets('pending item reject path calls reject use case', (tester) async {
    when(
      () => rejectUseCase.execute(any()),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(host());

    await tester.tap(find.byType(NasabahListItem));
    await tester.pumpAndSettle();

    // Action sheet offers both directions; pick Tolak.
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    // Reject dialog (Tolak Pengajuan?) confirms with a catatan.
    await tester.enterText(find.byType(TextField), 'Data tidak valid');
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    final captured = verify(() => rejectUseCase.execute(captureAny()))
        .captured
        .single as DecideNasabahParams;
    expect(captured.id, 'NAS-0001');
    expect(captured.catatan, 'Data tidak valid');
  });
}
