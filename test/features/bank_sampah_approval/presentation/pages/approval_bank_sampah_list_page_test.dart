import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';

import '../../../../support/nasabah_approval_support.dart';

const _pending = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati No. 5',
  status: MembershipStatus.pending,
  isActive: true,
);

const _approved = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.approved,
  isActive: true,
);

Widget _wrap(TestNasabahApprovalNotifier notifier) => ProviderScope(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
      child: const MaterialApp(home: ApprovalBankSampahListView()),
    );

TestNasabahApprovalNotifier _notifier(NasabahApprovalState state) =>
    TestNasabahApprovalNotifier(initialState: state);

void main() {
  testWidgets('renders one card per membership with the right status badge',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_notifier(const NasabahApprovalLoaded([_pending, _approved]))));

    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);
    expect(find.text('Bandung · Jl. Melati No. 5'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
    expect(find.text('Jakarta · Jl. Sudirman No. 20'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.byIcon(Icons.recycling), findsNWidgets(2));
  });

  testWidgets('loads memberships when the provider starts initial',
      (tester) async {
    final notifier = _notifier(const NasabahApprovalInitial());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [false]);
  });

  testWidgets('pulling to refresh reloads silently', (tester) async {
    final notifier =
        _notifier(const NasabahApprovalLoaded([_pending, _approved]));
    await tester.pumpWidget(_wrap(notifier));
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
  });

  testWidgets('renders EmptyView when there are no memberships',
      (tester) async {
    await tester.pumpWidget(_wrap(_notifier(const NasabahApprovalLoaded([]))));
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('renders skeletons while loading', (tester) async {
    await tester.pumpWidget(_wrap(_notifier(const NasabahApprovalLoading())));
    // SkeletonListItem runs its own Timer.periodic animation loop, so settle
    // would time out waiting for it to go idle.
    await tester.pump();

    expect(find.byType(SkeletonListItem), findsWidgets);
  });

  testWidgets('renders EmptyView with the message on error', (tester) async {
    await tester.pumpWidget(
        _wrap(_notifier(const NasabahApprovalError('Gagal memuat'))));

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Gagal memuat'), findsOneWidget);
  });
}
