import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';

import '../../../../support/nasabah_approval_support.dart';

/// PIL-539: a nasabah who already has a membership can apply to another bank
/// sampah from "Bank sampah saya".
const _applyRoute = '/ajukan-bank-sampah';

const _approved = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.approved,
  isActive: true,
  dapatDibuka: true,
);

void main() {
  Future<(TestNasabahApprovalNotifier, GoRouter)> pumpList(
    WidgetTester tester,
    NasabahApprovalState state,
  ) async {
    final notifier = TestNasabahApprovalNotifier(initialState: state);
    final router = GoRouter(
      initialLocation: ApprovalBankSampahListPage.route,
      routes: [
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (_, __) => const ApprovalBankSampahListView(),
        ),
        GoRoute(
          path: _applyRoute,
          builder: (context, __) => Scaffold(
            body: Column(children: [
              const Text('route:$_applyRoute'),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text('submitted'),
              ),
            ]),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        nasabahApprovalProvider.overrideWith(() => notifier),
        activeMembershipSelectionProvider
            .overrideWithValue(ActiveMembershipSelection.none()),
        activeMembershipUserIdProvider.overrideWithValue('user-1'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return (notifier, router);
  }

  testWidgets(
      'a nasabah with a membership can open the registration for another '
      'bank from here', (tester) async {
    await pumpList(tester, const NasabahApprovalLoaded([_approved]));

    await tester.tap(find.text('Ajukan bank baru'));
    await tester.pumpAndSettle();

    expect(find.text('route:$_applyRoute'), findsOneWidget);
  });

  testWidgets('a submitted application reloads the list on the way back',
      (tester) async {
    final (notifier, _) =
        await pumpList(tester, const NasabahApprovalLoaded([_approved]));

    await tester.tap(find.text('Ajukan bank baru'));
    await tester.pumpAndSettle();
    notifier.loadCalls.clear();
    await tester.tap(find.text('submitted'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
    expect(notifier.loadCalls, [true]);
  });

  testWidgets('going back without applying leaves the list as it was',
      (tester) async {
    final (notifier, router) =
        await pumpList(tester, const NasabahApprovalLoaded([_approved]));

    await tester.tap(find.text('Ajukan bank baru'));
    await tester.pumpAndSettle();
    notifier.loadCalls.clear();
    router.pop();
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, isEmpty);
  });

  testWidgets('an account with no membership is not offered another bank',
      (tester) async {
    await pumpList(tester, const NasabahApprovalLoaded([]));

    expect(find.text('Belum Ada Pengajuan'), findsOneWidget);
    expect(find.text('Ajukan bank baru'), findsNothing);
  });
}
