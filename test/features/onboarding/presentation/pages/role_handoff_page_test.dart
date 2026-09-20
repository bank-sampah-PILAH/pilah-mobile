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
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  testWidgets('lets a role handoff user sign out and return to login',
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
      BlocProvider<AuthenticationBloc>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Keluar dan ganti akun'));
    verify(() => auth.add(any<AuthenticationEvent>(
          that: isA<LogoutRequested>(),
        ))).called(1);

    states.add(Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });
}
