import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';

class _Repository extends PreviewNasabahRepository {
  final requests = <Completer<NasabahIdentity>>[];

  @override
  Future<NasabahIdentity> profile() {
    final request = Completer<NasabahIdentity>();
    requests.add(request);
    return request.future;
  }
}

Authenticated _session({String id = 'a', String token = 'first'}) =>
    Authenticated(
        authEntity: AuthEntity(
      id: id,
      name: 'Session name',
      email: '$id@example.test',
      photoUrl: '',
      token: token,
      role: 'nasabah',
      nextStep: 'dashboard',
    ));

void main() {
  late TestAuthenticationNotifier auth;
  late _Repository repository;

  setUp(() {
    auth = authNotifierIn(_session());
    repository = _Repository();
    di.registerSingleton<NasabahRepository>(repository);
  });

  tearDown(() async {
    await di.unregister<NasabahRepository>();
  });

  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(initialLocation: '/profile', routes: [
      GoRoute(path: '/profile', builder: (_, __) => const ProfilNasabahPage()),
      GoRoute(
          path: LoginPage.route,
          builder: (_, __) => const Scaffold(body: Text('LOGIN'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
        auth, MaterialApp.router(routerConfig: router)));
  }

  testWidgets('token refresh retains profile and does not repeat the request',
      (tester) async {
    await open(tester);
    repository.requests.single.complete(
        const NasabahIdentity('a', 'Alice', 'a@example.test', 'nasabah'));
    await tester.pumpAndSettle();
    auth.setStateForTest(_session(token: 'refreshed'));
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(1));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.requests, hasLength(2));
    repository.requests.last.complete(const NasabahIdentity(
        'a', 'Alice updated', 'a@example.test', 'nasabah'));
    await tester.pumpAndSettle();
    expect(find.text('Alice updated'), findsOneWidget);
  });

  testWidgets('account change discards the previous account pending response',
      (tester) async {
    await open(tester);
    auth.setStateForTest(_session(id: 'b'));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    repository.requests.last.complete(
        const NasabahIdentity('b', 'Bob', 'b@example.test', 'nasabah'));
    await tester.pumpAndSettle();
    repository.requests.first.complete(
        const NasabahIdentity('a', 'Alice', 'a@example.test', 'nasabah'));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);

    // Navigating to LoginPage on logout is MainPage's shell listener's job
    // (see lib/features/main/presentation/pages/main_page.dart); this page,
    // built standalone here with no shell above it, just falls back to its
    // own "please sign in" copy once the session drops.
    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsNothing);
    expect(
        find.text('Silakan masuk untuk melihat profil Anda.'), findsOneWidget);
  });
}
