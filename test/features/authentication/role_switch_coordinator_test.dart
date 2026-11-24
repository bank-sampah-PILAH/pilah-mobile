import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

AuthEntity session(String role) => AuthEntity(
  id: 'u1', name: 'Siti', email: 'siti@example.test', photoUrl: '',
  token: 'access-$role', role: role, roles: const ['pengelola', 'nasabah'],
  nextStep: role == 'nasabah' ? 'nasabah_dashboard' : 'dashboard',
);

void main() {
  test('active or unowned roles never request a new session', () async {
    var requests = 0;
    final current = session('nasabah');
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (role) async {
        requests++;
        return RoleSwitchSession(session(role), 'refresh');
      },
      persistSession: (_, __) async {},
      resetRoleState: () {},
      publishSession: (_) {},
    );
    addTearDown(coordinator.dispose);
    await coordinator.switchTo('nasabah');
    await coordinator.switchTo('superadmin');
    expect(requests, 0);
  });

  test('publishes the new role only after persistence and cache reset', () async {
    for (final target in ['nasabah', 'pengelola']) {
      var current = session(target == 'nasabah' ? 'pengelola' : 'nasabah');
      final order = <String>[];
      late RoleSwitchCoordinator coordinator;
      coordinator = RoleSwitchCoordinator(
        readSession: () => current,
        requestRole: (role) async {
          order.add('request:$role');
          return RoleSwitchSession(session(role), 'refresh-$role');
        },
        persistSession: (access, refresh) async {
          expect(current.role, isNot(target));
          expect(access, 'access-$target');
          expect(refresh, 'refresh-$target');
          order.add('persist');
        },
        resetRoleState: () => order.add('reset'),
        publishSession: (auth) { current = auth; order.add('publish'); },
      );
      coordinator.addListener(() {
        if (coordinator.completedSession != null) order.add('observe');
      });
      await coordinator.switchTo(target);
      expect(current.role, target);
      expect(order, ['request:$target', 'persist', 'reset', 'publish', 'observe']);
      expect(coordinator.busy, isFalse);
      coordinator.dispose();
    }
  });
}

