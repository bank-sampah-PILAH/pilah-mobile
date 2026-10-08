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
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
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

/// The lead dev's rule: in the app the navigation sits at the bottom, in a
/// browser it sits on the left. So the shell picks the navigation *family* from
/// the platform, and uses width only to decide how much of the left-hand
/// navigation fits.
///
/// Choosing on width alone was wrong in both directions. A native phone held
/// sideways is wider than 840 and lost its bottom bar; a browser window
/// narrowed below 600 grew one.
void main() {
  Future<void> mountShell(
    WidgetTester tester, {
    required String role,
    required Size window,
    required bool isWeb,
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
          builder: (_, __, shell) =>
              MainPage(navigationShell: shell, isWebOverride: isWeb),
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

  group('the app always keeps its navigation at the bottom', () {
    testWidgets('a phone gets the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing);
    });

    testWidgets('a tablet keeps the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(820, 1180), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'width must not turn the app into a desktop layout');
    });

    testWidgets('a phone held sideways keeps the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(844, 390), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'this is the landscape bug: 844 is wide, but it is a phone');
    });
  });

  group('the browser always keeps its navigation on the left', () {
    testWidgets('a desktop window uses the rail', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900), isWeb: true);
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'showing both would offer the same menu twice');
    });

    testWidgets('a tablet window uses the rail', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(720, 900), isWeb: true);
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('a phone browser moves the menu behind a button',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'a 256px rail cannot share a 390px window with content');
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'a browser keeps its navigation on the left, not the bottom');
    });
  });

  group('navigating', () {
    testWidgets('the rail moves between branches', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900), isWeb: true);
      expect(find.text('body:/home'), findsOneWidget);

      await tester.tap(find.text('Nasabah'));
      await tester.pumpAndSettle();

      expect(find.text('body:/customers'), findsOneWidget);
    });

    testWidgets('the menu button opens a drawer that moves between branches',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(RoleNavigationDrawer), findsOneWidget);

      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();

      expect(find.text('body:/prices'), findsOneWidget);
    });

    testWidgets('widening the browser keeps the selected destination',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
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
