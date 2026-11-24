import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

AuthEntity session(String role) => AuthEntity(
  id: 'u1', name: 'Siti', email: 'siti@example.test', photoUrl: '',
  token: 'access-$role', role: role, roles: const ['pengelola', 'nasabah'],
  nextStep: role == 'nasabah' ? 'nasabah_dashboard' : 'dashboard',
);

void main() {
  test('invalid switch responses cannot replace the current session', () async {
    final invalid = [
      RoleSwitchSession(session('pengelola'), 'refresh'),
      RoleSwitchSession(session('nasabah'), ''),
      const RoleSwitchSession(AuthEntity(id: 'other', name: '', email: '',
        photoUrl: '', token: 'new', role: 'nasabah', nextStep: 'nasabah_dashboard'), 'refresh'),
      const RoleSwitchSession(AuthEntity(id: 'u1', name: '', email: '',
        photoUrl: '', token: '', role: 'nasabah', nextStep: 'nasabah_dashboard'), 'refresh'),
      const RoleSwitchSession(AuthEntity(id: 'u1', name: '', email: '',
        photoUrl: '', token: 'new', role: 'nasabah', nextStep: 'https://evil.test'), 'refresh'),
    ];
    for (final response in invalid) {
      var mutations = 0;
      final coordinator = RoleSwitchCoordinator(
        readSession: () => session('pengelola'),
        requestRole: (_) async => response,
        persistSession: (_, __) async { mutations++; },
        resetRoleState: () { mutations++; },
        publishSession: (_) { mutations++; },
      );
      await coordinator.switchTo('nasabah');
      expect(mutations, 0, reason: 'invalid response must not mutate a session');
      expect(coordinator.error, isNotNull);
      coordinator.dispose();
    }
  });

  test('failed switch keeps the old session and notifies a retryable error', () async {
    final current = session('pengelola');
    var mutations = 0;
    final coordinator = RoleSwitchCoordinator(
      readSession: () => current,
      requestRole: (_) => Future.error(TimeoutException('connection lost')),
      persistSession: (_, __) async { mutations++; },
      resetRoleState: () { mutations++; },
      publishSession: (_) { mutations++; },
    );
    addTearDown(coordinator.dispose);
    final observed = <String>[];
    coordinator.addListener(() {
      if (coordinator.error != null) observed.add(coordinator.error!);
    });
    await expectLater(coordinator.switchTo('nasabah'), completes);
    expect(mutations, 0);
    expect(coordinator.busy, isFalse);
    expect(coordinator.completedSession, isNull);
    expect(observed.single, contains('Role sebelumnya tetap aktif'));
  });

  test('repeated taps share one pending switch', () async {
    var requests = 0;
    final pending = Completer<RoleSwitchSession>();
    final coordinator = RoleSwitchCoordinator(
      readSession: () => session('pengelola'),
      requestRole: (_) { requests++; return pending.future; },
      persistSession: (_, __) async {}, resetRoleState: () {},
      publishSession: (_) {},
    );
    addTearDown(coordinator.dispose);
    final first = coordinator.switchTo('nasabah');
    final second = coordinator.switchTo('nasabah');
    expect(coordinator.busy, isTrue);
    final count = requests;
    pending.complete(RoleSwitchSession(session('nasabah'), 'refresh'));
    await Future.wait([first, second]);
    expect(count, 1);
  });

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

