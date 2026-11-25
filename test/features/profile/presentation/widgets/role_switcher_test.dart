import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/role_switcher.dart';

void main() {
  testWidgets('pending switch disables actions and failed switch offers retry',
      (tester) async {
    final semantics = tester.ensureSemantics();
    const auth = AuthEntity(
        id: 'u1',
        name: '',
        email: '',
        photoUrl: '',
        token: 'old',
        role: 'pengelola',
        roles: ['pengelola', 'nasabah']);
    final pending = Completer<RoleSwitchSession>();
    final coordinator = RoleSwitchCoordinator(
      readSession: () => auth,
      requestRole: (_) => pending.future,
      persistSession: (_, __) async {},
      resetRoleState: () {},
      publishSession: (_) => fail('failed switch must not publish'),
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RoleSwitcher(auth: auth, coordinator: coordinator))));
    await tester.tap(find.text('Gunakan role ini'));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Mengganti role')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    pending.completeError(StateError('connection lost'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Role sebelumnya tetap aktif'), findsOneWidget);
    expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNotNull);
    expect(find.text('Aktif'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
    coordinator.dispose();
  });

  testWidgets(
      'Role saya shows owned roles and switches through the coordinator',
      (tester) async {
    for (final role in ['pengelola', 'nasabah']) {
      final auth = AuthEntity(
          id: 'u1',
          name: 'Siti',
          email: '',
          photoUrl: '',
          token: 'old',
          role: role,
          roles: const ['pengelola', 'nasabah']);
      final target = role == 'nasabah' ? 'pengelola' : 'nasabah';
      var requested = '';
      final coordinator = RoleSwitchCoordinator(
        readSession: () => auth,
        requestRole: (value) async {
          requested = value;
          return RoleSwitchSession(
              AuthEntity(
                  id: 'u1',
                  name: 'Siti',
                  email: '',
                  photoUrl: '',
                  token: 'new',
                  role: value,
                  nextStep:
                      value == 'nasabah' ? 'nasabah_dashboard' : 'dashboard'),
              'refresh');
        },
        persistSession: (_, __) async {},
        resetRoleState: () {},
        publishSession: (_) {},
      );
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: RoleSwitcher(auth: auth, coordinator: coordinator))));
      expect(find.text('Role saya'), findsOneWidget);
      expect(find.text('Nasabah'), findsOneWidget);
      expect(find.text('Pengurus'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      await tester.tap(find.text('Gunakan role ini'));
      await tester.pumpAndSettle();
      expect(requested, target);
      await tester.pumpWidget(const SizedBox.shrink());
      coordinator.dispose();
    }
  });
}
