import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockNasabahApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

class _MockNasabahAppealCubit extends MockCubit<NasabahAppealState>
    implements NasabahAppealCubit {}

const _first = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati No. 5',
  status: MembershipStatus.approved,
  isActive: true,
);

const _second = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.pending,
  isActive: true,
);

void main() {
  testWidgets('tapping a list card pushes the detail route with the entity',
      (tester) async {
    final cubit = _MockNasabahApprovalCubit();
    // Two memberships so the assertion can't be satisfied by the list page
    // alone: if the push never happened, the second card's own text would
    // still be onstage from the list, but the detail page's own widget
    // (carrying the tapped entity) and its "Riwayat Persetujuan" section
    // would not be.
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_first, _second]));

    final appealCubit = _MockNasabahAppealCubit();
    when(() => appealCubit.state).thenReturn(const NasabahAppealIdle());
    if (di.isRegistered<NasabahAppealCubit>()) {
      di.unregister<NasabahAppealCubit>();
    }
    di.registerFactory<NasabahAppealCubit>(() => appealCubit);
    addTearDown(() {
      if (di.isRegistered<NasabahAppealCubit>()) {
        di.unregister<NasabahAppealCubit>();
      }
    });

    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => BlocProvider<NasabahApprovalCubit>.value(
            value: cubit,
            child: const ApprovalBankSampahListView(),
          ),
        ),
        GoRoute(
          path: ApprovalBankSampahDetailPage.route,
          builder: (context, state) => ApprovalBankSampahDetailPage(
            membership: state.extra as NasabahMembershipEntity,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Bank Sampah Lestari'), findsOneWidget);

    await tester.tap(find.text('Bank Sampah Lestari'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Persetujuan'), findsOneWidget);
    final detailPage = tester.widget<ApprovalBankSampahDetailPage>(
      find.byType(ApprovalBankSampahDetailPage),
    );
    expect(detailPage.membership.id, 'membership-2');
  });

  testWidgets(
      'reloads memberships silently when returning from detail with changes',
      (tester) async {
    final cubit = _MockNasabahApprovalCubit();
    when(() => cubit.state).thenReturn(const NasabahApprovalLoaded([_first]));
    when(() => cubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});

    // A stand-in detail route, not the real ApprovalBankSampahDetailPage: the
    // detail page's own appeal-success-pops-true behaviour is already covered
    // in approval_bank_sampah_detail_page_test.dart. This isolates the list
    // page's own responsibility — reacting to whatever the pushed route pops
    // with — from that collaborator.
    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => BlocProvider<NasabahApprovalCubit>.value(
            value: cubit,
            child: const ApprovalBankSampahListView(),
          ),
        ),
        GoRoute(
          path: ApprovalBankSampahDetailPage.route,
          builder: (context, state) => TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Fake Detail'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake Detail'));
    await tester.pumpAndSettle();

    verify(() => cubit.load(silent: true)).called(1);
  });

  testWidgets('does not reload when returning from detail without changes',
      (tester) async {
    final cubit = _MockNasabahApprovalCubit();
    when(() => cubit.state).thenReturn(const NasabahApprovalLoaded([_first]));
    when(() => cubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => BlocProvider<NasabahApprovalCubit>.value(
            value: cubit,
            child: const ApprovalBankSampahListView(),
          ),
        ),
        GoRoute(
          path: ApprovalBankSampahDetailPage.route,
          builder: (context, state) => TextButton(
            onPressed: () => context.pop(),
            child: const Text('Fake Detail'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake Detail'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.load(silent: true));
  });
}
