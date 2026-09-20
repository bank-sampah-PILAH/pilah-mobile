import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';

void main() {
  group('DemoLoginProfiles', () {
    test('uses backend-compatible tokens for every seeded local role', () {
      expect(
        DemoLoginProfiles.operator.idToken,
        'dev:operator.demo@example.com:Operator PILAH E2E',
      );
      expect(
        DemoLoginProfiles.pendingOperator.idToken,
        'dev:pending.operator.demo@example.com:Operator Pending PILAH E2E',
      );
      expect(
        DemoLoginProfiles.customer.idToken,
        'dev-nasabah:customer.demo@example.com:Nasabah PILAH E2E',
      );
      expect(
        DemoLoginProfiles.superadmin.idToken,
        'dev-superadmin:superadmin.demo@example.com:Superadmin PILAH E2E',
      );
    });

    test('exposes the seeded profiles in login-sheet order', () {
      expect(
        DemoLoginProfiles.all.map((profile) => profile.label),
        [
          'Operator aktif',
          'Operator menunggu persetujuan',
          'Nasabah',
          'Superadmin',
        ],
      );
    });
  });
}
