import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

import '../../../../support/nasabah_approval_support.dart';

NasabahMembershipEntity _membership(MembershipStatus status) =>
    NasabahMembershipEntity(
      id: 'membership-${status.name}',
      bankSampahId: 'bank',
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
    final notifier = TestNasabahApprovalNotifier(initialState: state);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: NasabahVerificationHome(name: name),
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
    await tester.pumpWidget(ProviderScope(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    return notifier;
  }

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
}
