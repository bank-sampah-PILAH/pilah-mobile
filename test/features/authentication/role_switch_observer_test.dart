import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/role_switch_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/role_switch_observer.dart';
import '../../support/auth_support.dart';

void main() {
  testWidgets('observer replaces profile navigation using the switched next_step', (tester) async {
    const current = AuthEntity(id: 'u1', name: '', email: '', photoUrl: '',
      token: 'old', role: 'nasabah', roles: ['nasabah', 'pengelola']);
    const next = AuthEntity(id: 'u1', name: '', email: '', photoUrl: '',
      token: 'new', role: 'pengelola', roles: ['nasabah', 'pengelola'],
      nextStep: 'approval_pending');
    final auth = authNotifierIn(Authenticated(authEntity: current));
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (_) async => const RoleSwitchSession(next, 'refresh'),
      persistSession: (_, __) async {}, resetRoleState: () {},
      publishSession: (value) => auth.setStateForTest(Authenticated(authEntity: value)),
    );
    final router = GoRouter(initialLocation: '/profile', routes: [
      for (final path in ['/profile', '/pending-approval', '/login'])
        GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(path))),
    ]);
    await tester.pumpWidget(ProviderScope(overrides: [
      authenticationProvider.overrideWith(() => auth),
      roleSwitchProvider.overrideWith((_) => coordinator),
    ], child: RoleSwitchObserver(navigate: router.go,
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
