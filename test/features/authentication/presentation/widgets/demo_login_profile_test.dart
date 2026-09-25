import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';

class _FakeEnvironment implements AppEnvironment {
  @override
  String get baseUrl => '';

  @override
  bool get supportsDemoLogin => true;

  @override
  String get demoOperatorEmail => 'op@overridden.example.com';

  @override
  String get demoPendingOperatorEmail => 'pending@overridden.example.com';

  @override
  String get demoCustomerEmail => 'customer@overridden.example.com';

  @override
  String get demoNewNasabahEmail => 'fresh@overridden.example.com';

  @override
  String get demoIndukEmail => 'induk@overridden.example.com';

  @override
  String get demoSuperadminEmail => 'superadmin@overridden.example.com';
}

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
        DemoLoginProfiles.newNasabah.idToken,
        'dev-nasabah:nasabah.baru.demo@example.com:Nasabah Baru PILAH E2E',
      );
      expect(
        DemoLoginProfiles.induk.idToken,
        'dev-pengelola-induk:induk.demo@example.com:Pengelola Induk PILAH E2E',
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
          'Nasabah Baru (Pendaftaran)',
          'Pengelola Bank Sampah Induk',
          'Superadmin',
        ],
      );
    });

    test(
        'forEnvironment overrides every profile\'s email, keeping label/name/prefix',
        () {
      final profiles = DemoLoginProfiles.forEnvironment(_FakeEnvironment());

      expect(
        profiles.map((p) => p.email),
        [
          'op@overridden.example.com',
          'pending@overridden.example.com',
          'customer@overridden.example.com',
          'fresh@overridden.example.com',
          'induk@overridden.example.com',
          'superadmin@overridden.example.com',
        ],
      );
      expect(
        profiles.map((p) => p.label),
        DemoLoginProfiles.all.map((p) => p.label),
      );
      expect(
        profiles.map((p) => p.tokenPrefix),
        DemoLoginProfiles.all.map((p) => p.tokenPrefix),
      );
    });
  });
}
