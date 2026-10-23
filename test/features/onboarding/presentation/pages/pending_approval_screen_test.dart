import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

void main() {
  Future<void> open(
      WidgetTester tester, TestAuthenticationNotifier auth) async {
    await pumpRouted(
      tester,
      withAuthenticationProvider(
        auth,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        PendingApprovalScreen(),
      ),
      extraRoutes: ['/login'],
      size: const Size(800, 1800),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tells the applicant the registration is under review',
      (tester) async {
    await open(tester, authNotifierIn(Authenticated(authEntity: testAuth())));

    expect(find.text('Pendaftaran Terkirim!'), findsOneWidget);
    expect(find.text('Sedang Diproses'), findsOneWidget);
    expect(find.text('Profil diri dilengkapi'), findsOneWidget);
    expect(find.text('Ditinjau Admin (Tahap Saat Ini)'), findsOneWidget);
  });

  testWidgets('going back to login asks the bloc to log out', (tester) async {
    final bloc = authNotifierIn(Authenticated(authEntity: testAuth()));
    await open(tester, bloc);

    await tester.tap(find.text('Kembali ke Halaman Login'));
    await tester.pump();

    expect(bloc.calls, contains('logout'));
  });

  testWidgets('routes to login once the session is gone', (tester) async {
    final auth = authNotifierIn(Authenticated(authEntity: testAuth()));

    await open(tester, auth);
    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('route:/login'), findsOneWidget);
  });
}
