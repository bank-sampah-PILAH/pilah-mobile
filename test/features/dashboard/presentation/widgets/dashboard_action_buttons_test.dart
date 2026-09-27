import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
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
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

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

NasabahEntity _nasabah(String id, String name) => NasabahEntity(
      id: id,
      idNasabah: id,
      name: name,
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
  testWidgets('opens the Nasabah tab and then the add form', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
          routes: [
            GoRoute(
              path: 'nasabah',
              builder: (_, __) => const Scaffold(body: Text('Daftar Nasabah')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Tambah\nNasabah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Nasabah'), findsOneWidget);
    expect(find.text('Tambah Nasabah'), findsOneWidget);
  });

  testWidgets('opens setoran and payout history routes', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
        ),
        GoRoute(
          path: TransaksiBaruPage.route,
          builder: (_, __) => const Scaffold(body: Text('Form Setoran')),
        ),
        GoRoute(
          path: RiwayatPencairanPage.route,
          builder: (_, __) => const Scaffold(body: Text('Daftar Pencairan')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Setoran Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Form Setoran'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat Pencairan'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });

  testWidgets(
      'opens the active-nasabah picker and forwards the pick to Catat Pencairan',
      (tester) async {
    final getActiveUseCase = _MockGetActiveNasabahUseCase();
    when(() => getActiveUseCase.execute()).thenAnswer(
      (_) async => Right(HalamanNasabah(
        items: [_nasabah('n-1', 'Nasabah Satu')],
        totalCount: 1,
        hasMore: false,
      )),
    );
    final nasabahCubit = NasabahCubit(
      _MockGetNasabahUseCase(),
      getActiveUseCase,
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
    );
    addTearDown(nasabahCubit.close);

    CatatPencairanArgs? openedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
        ),
        GoRoute(
          path: CatatPencairanPage.route,
          builder: (context, state) {
            openedWith = state.extra as CatatPencairanArgs;
            return const Scaffold(body: Text('Form Pencairan'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<NasabahCubit>.value(
        value: nasabahCubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Catat Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Nasabah Satu'), findsOneWidget);
    await tester.tap(find.text('Nasabah Satu'));
    await tester.pumpAndSettle();

    expect(find.text('Form Pencairan'), findsOneWidget);
    expect(openedWith?.nasabahId, 'n-1');
    expect(openedWith?.nasabahNama, 'Nasabah Satu');
  });
}
