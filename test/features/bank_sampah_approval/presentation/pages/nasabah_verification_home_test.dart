import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/bank_membership_panel.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

import '../../../../support/active_membership_support.dart';
import '../../../../support/auth_support.dart';
import '../../../../support/nasabah_approval_support.dart';

NasabahMembershipEntity _membership(MembershipStatus status) =>
    NasabahMembershipEntity(
      id: 'membership-${status.name}',
      bankSampahId: 'bank-${status.name}',
      bankSampahNama: 'Bank Sampah Melati',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Melati',
      status: status,
      isActive: false,
    );

void main() {
  Future<TestNasabahApprovalNotifier> pumpHome(
    WidgetTester tester,
    NasabahApprovalState state, {
    String name = 'Siti',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notifier = TestNasabahApprovalNotifier(initialState: state);
    final storage = MemoryAppStorage();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: NasabahVerificationHome(name: name),
        ),
      ),
      GoRoute(
        path: ApprovalBankSampahListPage.route,
        builder: (context, routeState) => BankMembershipPanel(
          owner: const AuthEntity(
            id: 'nasabah-1',
            name: 'Siti',
            email: 'siti@example.test',
            photoUrl: '',
            token: 'token-1',
            role: 'nasabah',
          ),
          scrollToHistory: routeState.uri.queryParameters['tab'] == 'history',
        ),
      ),
      GoRoute(
        path: RegisterNasabahScreen.route,
        builder: (_, __) => const Scaffold(body: Text('form pengajuan')),
      ),
      GoRoute(
        path: ApprovalBankSampahDetailPage.route,
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(),
            child:
                Text('detail ${(state.extra! as NasabahMembershipEntity).id}'),
          ),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    final auth = authNotifierIn(Authenticated(
      authEntity: const AuthEntity(
        id: 'nasabah-1',
        name: 'Siti',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'token-1',
        role: 'nasabah',
      ),
    ));
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
      overrides: [
        nasabahApprovalProvider.overrideWith(() => notifier),
        activeMembershipSelectionProvider.overrideWithValue(
          ActiveMembershipSelection(storage),
        ),
        activeMembershipUserIdProvider.overrideWithValue('nasabah-1'),
      ],
    ));
    await tester.pump();
    return notifier;
  }

  testWidgets('verification opens Bank sampah saya directly at history',
      (tester) async {
    await pumpHome(
      tester,
      NasabahApprovalLoaded([_membership(MembershipStatus.pending)]),
    );

    await tester.tap(find.text('Bank sampah saya'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah Melati'), findsOneWidget);
    expect(find.text('Belum ada riwayat pengajuan'), findsNothing);
    expect(find.text('Belum ada bank yang diikuti'), findsNothing);
  });

  testWidgets('refreshes the status after returning from the list',
      (tester) async {
    final notifier = await pumpHome(
      tester,
      NasabahApprovalLoaded([_membership(MembershipStatus.pending)]),
    );
    notifier.loadCalls.clear();

    await tester.tap(find.text('Bank sampah saya'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The full page loads on entry; verification refreshes when it closes.
    expect(notifier.loadCalls, [false, true]);
  });

  testWidgets('greets the nasabah while status loads', (tester) async {
    await pumpHome(tester, const NasabahApprovalLoading());
    expect(find.text('Halo, Siti'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('uses a generic greeting when the name is empty', (tester) async {
    await pumpHome(tester, const NasabahApprovalInitial(), name: '');
    expect(find.text('Halo, Nasabah'), findsOneWidget);
  });

  testWidgets('a failed status load can be retried', (tester) async {
    final notifier =
        await pumpHome(tester, const NasabahApprovalError('Jaringan terputus'));
    expect(find.text('Status belum bisa dimuat'), findsOneWidget);
    expect(find.text('Jaringan terputus'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [false]);
  });

  testWidgets('with no membership it offers to apply for one', (tester) async {
    await pumpHome(tester, const NasabahApprovalLoaded([]));
    expect(find.text('Belum ada pengajuan'), findsOneWidget);

    await tester.tap(find.text('Ajukan keanggotaan'));
    await tester.pumpAndSettle();

    expect(find.text('form pengajuan'), findsOneWidget);
  });

  testWidgets('shows a pending request first and refreshes after its detail',
      (tester) async {
    final notifier = await pumpHome(
        tester,
        NasabahApprovalLoaded([
          _membership(MembershipStatus.approved),
          _membership(MembershipStatus.rejected),
          _membership(MembershipStatus.pending),
        ]));
    expect(find.text('Pengajuan sedang ditinjau'), findsOneWidget);

    await tester.ensureVisible(find.text('Lihat detail pengajuan'));
    await tester.tap(find.text('Lihat detail pengajuan'));
    await tester.pumpAndSettle();
    expect(find.text('detail membership-pending'), findsOneWidget);

    await tester.tap(find.text('detail membership-pending'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
  });

  testWidgets('falls back to a rejected membership', (tester) async {
    await pumpHome(
        tester,
        NasabahApprovalLoaded([
          _membership(MembershipStatus.approved),
          _membership(MembershipStatus.rejected),
        ]));
    expect(find.text('Pengajuan belum disetujui'), findsOneWidget);
  });

  testWidgets('falls back to any membership when none is pending or rejected',
      (tester) async {
    await pumpHome(tester,
        NasabahApprovalLoaded([_membership(MembershipStatus.approved)]));
    expect(find.text('Keanggotaan belum aktif'), findsOneWidget);
  });

  testWidgets('pulling down reloads the status silently', (tester) async {
    final notifier = await pumpHome(
        tester, NasabahApprovalLoaded([_membership(MembershipStatus.pending)]));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
  });

  testWidgets('shows the same icon for the link as the beranda does',
      (tester) async {
    await pumpHome(
        tester, NasabahApprovalLoaded([_membership(MembershipStatus.pending)]));

    // One destination, one glyph. The wallet is the nav rail's Tabungan icon,
    // so using it here pointed this link at another feature as well.
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
  });
}
