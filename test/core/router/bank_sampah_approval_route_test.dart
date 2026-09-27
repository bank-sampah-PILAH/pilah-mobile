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
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

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
  late _MockNasabahApprovalCubit approvalCubit;

  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());

    approvalCubit = _MockNasabahApprovalCubit();
    when(() => approvalCubit.state)
        .thenReturn(const NasabahApprovalLoaded([_membership]));
    when(() => approvalCubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
    }
    di.registerFactory<NasabahApprovalCubit>(() => approvalCubit);
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
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

    expect(find.text('Lihat Status Approval Bank Sampah'), findsOneWidget);

    await tester.tap(find.text('Lihat Status Approval Bank Sampah'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval Bank Sampah'), findsOneWidget);
    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);

    await tester.tap(find.text('Bank Sampah Sejahtera'));
    await tester.pumpAndSettle();

    expect(find.text('Bandung'), findsOneWidget);
  });
}
