import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

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
  late _MockNasabahApprovalCubit approvalCubit;

  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());

    approvalCubit = _MockNasabahApprovalCubit();
    when(() => approvalCubit.state)
        .thenReturn(const NasabahApprovalLoaded([_first, _second]));
    when(() => approvalCubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
    }
    di.registerFactory<NasabahApprovalCubit>(() => approvalCubit);

    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());

    final appealCubit = _MockNasabahAppealCubit();
    when(() => appealCubit.state).thenReturn(const NasabahAppealIdle());
    if (di.isRegistered<NasabahAppealCubit>()) {
      di.unregister<NasabahAppealCubit>();
    }
    di.registerFactory<NasabahAppealCubit>(() => appealCubit);
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
    }
    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    if (di.isRegistered<NasabahAppealCubit>()) {
      di.unregister<NasabahAppealCubit>();
    }
  });

  testWidgets(
      'nasabah dashboard entry point reaches the approval list and detail routes',
      (tester) async {
    final authenticationBloc = _MockAuthenticationBloc();
    final authenticationStates = StreamController<AuthenticationStates>();
    addTearDown(authenticationStates.close);
    addTearDown(authenticationBloc.close);
    whenListen(
      authenticationBloc,
      authenticationStates.stream,
      initialState: Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Ayu Lestari',
          email: 'ayu@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );

    final router = AppRouterConfig.getRouter();
    router.go(RoleHandoffPage.nasabahDashboardRoute);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: authenticationBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Status Approval Bank Sampah'), findsOneWidget);

    await tester.tap(find.text('Status Approval Bank Sampah'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval Bank Sampah'), findsOneWidget);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);

    await tester.tap(find.text('Bank Sampah Lestari'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Persetujuan'), findsOneWidget);
    final detailPage = tester.widget<ApprovalBankSampahDetailPage>(
      find.byType(ApprovalBankSampahDetailPage),
    );
    expect(detailPage.membership.id, 'membership-2');
  });
}
