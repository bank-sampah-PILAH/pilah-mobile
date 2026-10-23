import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/nasabah_approval_support.dart';

class _MockAppealMembershipUseCase extends Mock
    implements AppealMembershipUseCase {}

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
    final notifier = TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalLoaded([_first, _second]),
    );
    final appealUseCase = _MockAppealMembershipUseCase();
    if (di.isRegistered<AppealMembershipUseCase>()) {
      di.unregister<AppealMembershipUseCase>();
    }
    di.registerFactory<AppealMembershipUseCase>(() => appealUseCase);
    addTearDown(() {
      if (di.isRegistered<AppealMembershipUseCase>()) {
        di.unregister<AppealMembershipUseCase>();
      }
    });

    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => const ApprovalBankSampahListView(),
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

    await tester.pumpWidget(ProviderScope(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ));
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
    final notifier = TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalLoaded([_first]),
    );
    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => const ApprovalBankSampahListView(),
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

    await tester.pumpWidget(ProviderScope(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake Detail'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
  });

  testWidgets('does not reload when returning from detail without changes',
      (tester) async {
    final notifier = TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalLoaded([_first]),
    );
    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (context, state) => const ApprovalBankSampahListView(),
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

    await tester.pumpWidget(ProviderScope(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake Detail'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, isEmpty);
  });
}
