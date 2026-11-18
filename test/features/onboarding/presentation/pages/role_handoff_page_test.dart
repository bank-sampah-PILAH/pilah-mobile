import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/auth_support.dart';

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  testWidgets('lets a role handoff user sign out and return to login',
      (tester) async {
    final auth = authNotifierIn(Authenticated(
      authEntity: const AuthEntity(
        name: 'Ayu Lestari',
        email: 'ayu@example.com',
        photoUrl: '',
        token: 'jwt',
        role: 'nasabah',
      ),
    ));
    final originalGoogleSignInPlatform =
        google_sign_in.GoogleSignInPlatform.instance;
    final googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    final signOutCompleted = Completer<void>();
    when(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) => signOutCompleted.future);
    addTearDown(() {
      google_sign_in.GoogleSignInPlatform.instance =
          originalGoogleSignInPlatform;
    });

    final router = GoRouter(
      initialLocation: RoleHandoffPage.nasabahDashboardRoute,
      routes: [
        GoRoute(
          path: RoleHandoffPage.nasabahDashboardRoute,
          builder: (_, __) => const RoleHandoffPage(
            title: 'Akun Nasabah Siap',
            message: 'Beranda Nasabah sedang disiapkan.',
            registrationInProgress: false,
          ),
        ),
        GoRoute(
          path: LoginPage.route,
          builder: (_, __) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      withAuthenticationProvider(
        auth,
        MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Keluar dan ganti akun'));
    await tester.pump();
    expect(auth.calls, isNot(contains('logout')));

    signOutCompleted.complete();
    await tester.pumpAndSettle();
    verify(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .called(1);
    expect(auth.calls, contains('logout'));

    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('a failed Google sign-out reports it and does not log out',
      (tester) async {
    final auth = authNotifierIn(Authenticated(
      authEntity: const AuthEntity(
        name: 'Ayu Lestari',
        email: 'ayu@example.com',
        photoUrl: '',
        token: 'jwt',
        role: 'nasabah',
      ),
    ));
    final originalGoogleSignInPlatform =
        google_sign_in.GoogleSignInPlatform.instance;
    final googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    when(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) async => throw StateError('offline'));
    addTearDown(() {
      google_sign_in.GoogleSignInPlatform.instance =
          originalGoogleSignInPlatform;
    });
    await pumpRouted(
      tester,
      withAuthenticationProvider(
        auth,
        const RoleHandoffPage(
          title: 'Akun Nasabah Siap',
          message: 'Beranda Nasabah sedang disiapkan.',
          registrationInProgress: false,
        ),
      ),
    );

    await tester.tap(find.text('Keluar dan ganti akun'));
    await pumpToast(tester);

    expect(find.text('Ganti Akun Gagal'), findsOneWidget);
    expect(auth.calls, isNot(contains('logout')));
    await settleToasts(tester);
  });

  testWidgets('opens Nasabah history from the Nasabah landing page',
      (tester) async {
    final auth = authNotifierIn(Authenticated(
      authEntity: const AuthEntity(
        name: 'Ayu Lestari',
        email: 'ayu@example.com',
        photoUrl: '',
        token: 'jwt',
        role: 'nasabah',
      ),
    ));

    final router = GoRouter(
      initialLocation: RoleHandoffPage.nasabahDashboardRoute,
      routes: [
        GoRoute(
          path: RoleHandoffPage.nasabahDashboardRoute,
          builder: (_, __) => const RoleHandoffPage(
            title: 'Akun Nasabah Siap',
            message: 'Beranda Nasabah sedang disiapkan.',
            registrationInProgress: false,
            showPayoutHistory: true,
          ),
        ),
        GoRoute(
          path: AppLocations.history,
          builder: (_, state) => Scaffold(
            body: Text('Tabungan ${state.uri.queryParameters['filter']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      withAuthenticationProvider(
        auth,
        MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Riwayat Nasabah'));
    await tester.pumpAndSettle();

    expect(find.text('Tabungan pencairan'), findsOneWidget);
  });
}
