import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockNasabahApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

void main() {
  late _MockNasabahApprovalCubit approvalCubit;

  setUp(() {
    approvalCubit = _MockNasabahApprovalCubit();
    when(() => approvalCubit.state).thenReturn(const NasabahApprovalLoaded([]));
    when(() => approvalCubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
    }
    di.registerFactory<NasabahApprovalCubit>(() => approvalCubit);
  });

  tearDown(() {
    if (di.isRegistered<NasabahApprovalCubit>()) {
      di.unregister<NasabahApprovalCubit>();
    }
  });

  testWidgets('tapping the approval-status entry point pushes the list route',
      (tester) async {
    final auth = _MockAuthBloc();
    final states = StreamController<AuthenticationStates>();
    addTearDown(states.close);
    addTearDown(auth.close);
    whenListen(
      auth,
      states.stream,
      initialState: Authenticated(
        authEntity: const AuthEntity(
          name: 'Ayu Lestari',
          email: 'ayu@example.com',
          photoUrl: '',
          token: 'jwt',
          role: 'nasabah',
        ),
      ),
    );

    final router = GoRouter(
      initialLocation: RoleHandoffPage.nasabahDashboardRoute,
      routes: [
        GoRoute(
          path: RoleHandoffPage.nasabahDashboardRoute,
          builder: (_, __) => const RoleHandoffPage(
            title: 'Akun Nasabah Siap',
            message: 'Beranda Nasabah sedang disiapkan.',
            registrationInProgress: false,
            showApprovalStatusLink: true,
          ),
        ),
        GoRoute(
          path: ApprovalBankSampahListPage.route,
          builder: (_, __) => const ApprovalBankSampahListPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Lihat Status Approval Bank Sampah'), findsOneWidget);

    await tester.tap(find.text('Lihat Status Approval Bank Sampah'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval Bank Sampah'), findsOneWidget);
  });
}
