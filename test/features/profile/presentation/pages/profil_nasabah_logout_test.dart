import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';

Authenticated _session() => Authenticated(
        authEntity: const AuthEntity(
      id: 'nasabah-284',
      name: 'Siti Aminah',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'test-token',
      role: 'nasabah',
      nextStep: 'dashboard',
    ));

void main() {
  late TestAuthenticationNotifier auth;

  setUp(() {
    auth = authNotifierIn(_session());
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository(
        name: 'Siti Aminah', email: 'siti@example.test'));
  });

  tearDown(() async {
    await di.unregister<NasabahRepository>();
  });

  testWidgets('logging out asks first, then calls logout', (tester) async {
    await tester.pumpWidget(withAuthenticationProvider(
        auth, const MaterialApp(home: ProfilNasabahPage())));
    await tester.pumpAndSettle();

    final logoutButton = find.text('Keluar');
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(auth.calls, isNot(contains('logout')));

    await tester.tap(find.text('Ya, Keluar'));
    await tester.pumpAndSettle();

    expect(auth.calls, contains('logout'));
  });

  testWidgets('cancelling the logout keeps the session', (tester) async {
    await tester.pumpWidget(withAuthenticationProvider(
        auth, const MaterialApp(home: ProfilNasabahPage())));
    await tester.pumpAndSettle();

    final logoutButton = find.text('Keluar');
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(auth.calls, isNot(contains('logout')));
  });

  // Post-logout navigation to LoginPage is MainPage's shell listener's job
  // (lib/features/main/presentation/pages/main_page.dart), not this page's —
  // covered by profil_nasabah_test.dart's real-router assertion and by
  // role_navigation_test.dart. This page's only job on Unauthenticated is to
  // stop treating the session as a nasabah session, which the tests above
  // and in profil_nasabah_test.dart already cover.
}
