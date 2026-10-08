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
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockApproval extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

const _approved = NasabahMembershipEntity(
  id: 'application-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Melati',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati',
  status: MembershipStatus.approved,
  isActive: true,
);

/// The shell must choose a navigation *form* from the window width while the
/// destinations themselves stay decided by role. A Pengurus who widens their
/// browser should keep the same five destinations and the same selected page;
/// only the shape around them changes.
void main() {
  Future<void> mountShell(
    WidgetTester tester, {
    required String role,
    required Size window,
    String initialLocation = '/home',
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final approval = _MockApproval();
    when(() => approval.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    whenListen(approval, const Stream<NasabahApprovalState>.empty(),
        initialState: const NasabahApprovalLoaded([_approved]));
    di.registerFactory<NasabahApprovalCubit>(() => approval);
    addTearDown(() async {
      await di.unregister<NasabahApprovalCubit>();
      await approval.close();
    });

    final auth = _MockAuth();
    final state = Authenticated(
      authEntity: AuthEntity(
        name: 'Sari',
        email: 'sari@example.test',
        photoUrl: '',
        token: 'test',
        role: role,
        nextStep: 'dashboard',
      ),
    );
    when(() => auth.state).thenReturn(state);
    when(() => auth.stream).thenAnswer((_) => const Stream.empty());
    addTearDown(auth.close);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MainPage(navigationShell: shell),
          branches: [
            for (final path in [
              '/home',
              '/customers',
              '/prices',
              '/reports',
              '/schedule',
              '/history',
              '/bank',
              '/profile'
            ])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: path,
                    builder: (_, __) => Center(child: Text('body:$path'))),
              ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  group('shell navigation form', () {
    testWidgets('a phone keeps the bottom navigation bar', (tester) async {
      await mountShell(tester, role: 'pengelola', window: const Size(390, 844));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing);
    });

    testWidgets('a tablet swaps the bottom bar for a rail', (tester) async {
      await mountShell(tester, role: 'pengelola', window: const Size(720, 900));
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'showing both would offer the same menu twice');
    });

    testWidgets('a desktop window uses the rail', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900));
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('the rail still navigates between branches', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900));
      expect(find.text('body:/home'), findsOneWidget);

      await tester.tap(find.text('Nasabah'));
      await tester.pumpAndSettle();

      expect(find.text('body:/customers'), findsOneWidget);
    });

    testWidgets('resizing keeps the selected destination', (tester) async {
      await mountShell(tester, role: 'pengelola', window: const Size(390, 844));
      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();
      expect(find.text('body:/prices'), findsOneWidget);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();

      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.text('body:/prices'), findsOneWidget,
          reason: 'a resize must not send the user back to the dashboard');
    });
  });
}
