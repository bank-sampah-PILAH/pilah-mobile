import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  Future<void> open(WidgetTester tester, MockAuthBloc bloc) async {
    await pumpRouted(
      tester,
      BlocProvider<AuthenticationBloc>.value(
        value: bloc,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: PendingApprovalScreen(),
      ),
      extraRoutes: ['/login'],
      size: const Size(800, 1800),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tells the applicant the registration is under review',
      (tester) async {
    await open(tester, authBlocIn(Authenticated(authEntity: testAuth())));

    expect(find.text('Pendaftaran Terkirim!'), findsOneWidget);
    expect(find.text('Sedang Diproses'), findsOneWidget);
    expect(find.text('Profil diri dilengkapi'), findsOneWidget);
    expect(find.text('Ditinjau Admin (Tahap Saat Ini)'), findsOneWidget);
  });

  testWidgets('going back to login asks the bloc to log out', (tester) async {
    final bloc = authBlocIn(Authenticated(authEntity: testAuth()));
    await open(tester, bloc);

    await tester.tap(find.text('Kembali ke Halaman Login'));
    await tester.pump();

    verify(() => bloc.add(any(that: isA<LogoutRequested>()))).called(1);
  });

  testWidgets('routes to login once the session is gone', (tester) async {
    final bloc = MockAuthBloc();
    whenListen(
        bloc, Stream<AuthenticationStates>.fromIterable([Unauthenticated()]),
        initialState: Authenticated(authEntity: testAuth()));

    await open(tester, bloc);

    expect(find.text('route:/login'), findsOneWidget);
  });
}
