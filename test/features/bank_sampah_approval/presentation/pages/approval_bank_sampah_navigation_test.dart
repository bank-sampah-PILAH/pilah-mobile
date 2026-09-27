import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';

class _MockNasabahApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

const _membership = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  status: MembershipStatus.approved,
  isActive: true,
);

void main() {
  testWidgets('tapping a list card pushes the detail route with the entity',
      (tester) async {
    final cubit = _MockNasabahApprovalCubit();
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_membership]));

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

    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);

    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();

    // The detail page's AppBar title also reads the bank name, so the
    // membership's city is the more specific signal that the right entity
    // (not just a same-named stand-in) reached the detail page.
    expect(find.text('Bandung'), findsOneWidget);
  });
}
