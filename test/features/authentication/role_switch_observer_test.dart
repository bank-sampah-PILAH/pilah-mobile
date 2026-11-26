import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/role_switch_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/role_switch_observer.dart';
import '../../support/auth_support.dart';

void main() {
  testWidgets('default error feedback stays visible on the current profile',
      (tester) async {
    const current = AuthEntity(
        id: 'u1',
        name: '',
        email: '',
        photoUrl: '',
        token: 'old',
        role: 'pengelola',
        roles: ['nasabah', 'pengelola']);
    final auth = authNotifierIn(Authenticated(authEntity: current));
    final destinations = <String>[];
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (_) => Future.error(StateError('server refused')),
      persistSession: (_, __) async {},
      resetRoleState: () {},
      publishSession: (_) => fail('failed switch must not publish'),
    );
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      roleSwitchProvider.overrideWith((_) => coordinator),
    ]);
    addTearDown(container.dispose);
    final before = container.read(authenticationProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RoleSwitchObserver(
        navigate: destinations.add,
        child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            home: const Scaffold(body: Text('current profile'))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(rootNavigatorKey.currentContext, isNotNull);
    await coordinator.switchTo('nasabah');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gagal mengganti role'), findsOneWidget);
    expect(find.textContaining('Role sebelumnya tetap aktif'), findsOneWidget);
    expect(find.text('current profile'), findsOneWidget);
    expect(container.read(authenticationProvider), same(before));
    expect(destinations, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('observer reports failures without navigating or signing out',
      (tester) async {
    const current = AuthEntity(
        id: 'u1',
        name: '',
        email: '',
        photoUrl: '',
        token: 'old',
        role: 'pengelola',
        roles: ['nasabah', 'pengelola']);
    final auth = authNotifierIn(Authenticated(authEntity: current));
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (_) => Future.error(StateError('server refused')),
      persistSession: (_, __) async {},
      resetRoleState: () {},
      publishSession: (_) => fail('failed switch must not publish'),
    );
    final errors = <String>[];
    final destinations = <String>[];
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authenticationProvider.overrideWith(() => auth),
          roleSwitchProvider.overrideWith((_) => coordinator),
        ],
        child: RoleSwitchObserver(
            navigate: destinations.add,
            onError: errors.add,
            child: const MaterialApp(home: Scaffold(body: Text('profile'))))));
    await coordinator.switchTo('nasabah');
    await tester.pumpAndSettle();
    expect(errors, hasLength(1));
    expect(errors.single, contains('Role sebelumnya tetap aktif'));
    expect(destinations, isEmpty);
    expect(find.text('profile'), findsOneWidget);
    expect(auth.calls, isNot(contains('logout')));
  });

  testWidgets(
      'observer replaces profile navigation using the switched next_step',
      (tester) async {
    const current = AuthEntity(
        id: 'u1',
        name: '',
        email: '',
        photoUrl: '',
        token: 'old',
        role: 'nasabah',
        roles: ['nasabah', 'pengelola']);
    const next = AuthEntity(
        id: 'u1',
        name: '',
        email: '',
        photoUrl: '',
        token: 'new',
        role: 'pengelola',
        roles: ['nasabah', 'pengelola'],
        nextStep: 'approval_pending');
    final auth = authNotifierIn(Authenticated(authEntity: current));
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (_) async => const RoleSwitchSession(next, 'refresh'),
      persistSession: (_, __) async {},
      resetRoleState: () {},
      publishSession: (value) =>
          auth.setStateForTest(Authenticated(authEntity: value)),
    );
    final router = GoRouter(initialLocation: '/profile', routes: [
      for (final path in ['/profile', '/pending-approval', '/login'])
        GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(path))),
    ]);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authenticationProvider.overrideWith(() => auth),
          roleSwitchProvider.overrideWith((_) => coordinator),
        ],
        child: RoleSwitchObserver(
            navigate: router.go,
            child: MaterialApp.router(routerConfig: router))));
    await tester.pumpAndSettle();
    await coordinator.switchTo('pengelola');
    await tester.pumpAndSettle();
    expect(find.text('/pending-approval'), findsOneWidget);
    expect(find.text('/login'), findsNothing);
    expect(router.canPop(), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
