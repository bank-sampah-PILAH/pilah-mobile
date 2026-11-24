import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/role_switcher.dart';

void main() {
  testWidgets('Role saya shows owned roles and switches through the coordinator', (tester) async {
    for (final role in ['pengelola', 'nasabah']) {
      final auth = AuthEntity(id: 'u1', name: 'Siti', email: '', photoUrl: '',
        token: 'old', role: role, roles: const ['pengelola', 'nasabah']);
      final target = role == 'nasabah' ? 'pengelola' : 'nasabah';
      var requested = '';
      final coordinator = RoleSwitchCoordinator(
        readSession: () => auth,
        requestRole: (value) async {
          requested = value;
          return RoleSwitchSession(AuthEntity(id: 'u1', name: 'Siti', email: '',
            photoUrl: '', token: 'new', role: value,
            nextStep: value == 'nasabah' ? 'nasabah_dashboard' : 'dashboard'), 'refresh');
        },
        persistSession: (_, __) async {}, resetRoleState: () {}, publishSession: (_) {},
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body:
        RoleSwitcher(auth: auth, coordinator: coordinator))));
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
