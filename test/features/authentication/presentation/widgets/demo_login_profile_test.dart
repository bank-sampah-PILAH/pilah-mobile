import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';

class _StubEnvironment implements AppEnvironment {
  const _StubEnvironment();

  @override
  String get baseUrl => 'https://example.test';

  @override
  bool get supportsDemoLogin => true;

  @override
  String get demoPengurusEmail => 'configured.pengurus@example.com';

  @override
  String get demoPengelolaIndukEmail => 'configured.induk@example.com';

  @override
  String get demoCustomerEmail => 'configured.customer@example.com';

  @override
  String get demoSuperadminEmail => 'configured.superadmin@example.com';
}

Map<String, String> _readExampleEnv() {
  final values = <String, String>{};
  for (final line in File('.env.example').readAsLinesSync()) {
    final entry = line.trim();
    if (entry.isEmpty || entry.startsWith('#')) continue;
    final separator = entry.indexOf('=');
    if (separator > 0) {
      values[entry.substring(0, separator)] = entry.substring(separator + 1);
    }
  }
  return values;
}

void main() {
  group('DemoLoginProfiles', () {
    test('uses backend-compatible tokens for every seeded local role', () {
      expect(
        DemoLoginProfiles.pengurus.idToken,
        'dev:pengurus.demo@example.com:Pengurus PILAH E2E',
      );
      expect(
        DemoLoginProfiles.pengelolaInduk.idToken,
        'dev-pengelola-induk:induk.demo@example.com:Pengelola Induk PILAH E2E',
      );
      expect(
        DemoLoginProfiles.customer.idToken,
        'dev-nasabah:nasabah.demo@example.com:Nasabah PILAH E2E',
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
          'Pengurus',
          'Pengelola Induk',
          'Nasabah',
          'Superadmin',
        ],
      );
    });

    test('keeps seeded email constants aligned with the env example', () {
      final env = _readExampleEnv();

      expect(
        DemoLoginProfiles.pengurus.email,
        env['DEMO_PENGURUS_EMAIL'],
      );
      expect(
        DemoLoginProfiles.pengelolaInduk.email,
        env['DEMO_PENGELOLA_INDUK_EMAIL'],
      );
      expect(DemoLoginProfiles.customer.email, env['DEMO_CUSTOMER_EMAIL']);
      expect(
        DemoLoginProfiles.superadmin.email,
        env['DEMO_SUPERADMIN_EMAIL'],
      );
    });

    test('maps environment-configured emails and token prefixes', () {
      final profiles =
          DemoLoginProfiles.forEnvironment(const _StubEnvironment());

      expect(
        profiles.map((profile) => profile.email),
        [
          'configured.pengurus@example.com',
          'configured.induk@example.com',
          'configured.customer@example.com',
          'configured.superadmin@example.com',
        ],
      );
      expect(
        profiles.map((profile) => profile.tokenPrefix),
        [
          'dev',
          'dev-pengelola-induk',
          'dev-nasabah',
          'dev-superadmin',
        ],
      );
    });
  });
}
