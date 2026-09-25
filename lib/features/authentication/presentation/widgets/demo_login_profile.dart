import 'package:pilah_mobile/core/client/app_environment.dart';

class DemoLoginProfile {
  final String label;
  final String name;
  final String email;
  final String tokenPrefix;

  const DemoLoginProfile({
    required this.label,
    required this.name,
    required this.email,
    required this.tokenPrefix,
  });

  String get idToken => '$tokenPrefix:$email:$name';
}

abstract final class DemoLoginProfiles {
  static const pengurus = DemoLoginProfile(
    label: 'Pengurus',
    name: 'Pengurus PILAH E2E',
    email: 'pengurus.demo@example.com',
    tokenPrefix: 'dev',
  );

  static const pengelolaInduk = DemoLoginProfile(
    label: 'Pengelola Induk',
    name: 'Pengelola Induk PILAH E2E',
    email: 'induk.demo@example.com',
    tokenPrefix: 'dev-pengelola-induk',
  );

  static const customer = DemoLoginProfile(
    label: 'Nasabah',
    name: 'Nasabah PILAH E2E',
    email: 'nasabah.demo@example.com',
    tokenPrefix: 'dev-nasabah',
  );

  static const superadmin = DemoLoginProfile(
    label: 'Superadmin',
    name: 'Superadmin PILAH E2E',
    email: 'superadmin.demo@example.com',
    tokenPrefix: 'dev-superadmin',
  );

  static const all = <DemoLoginProfile>[
    pengurus,
    pengelolaInduk,
    customer,
    superadmin,
  ];

  static List<DemoLoginProfile> forEnvironment(AppEnvironment environment) => [
        DemoLoginProfile(
          label: pengurus.label,
          name: pengurus.name,
          email: pengurus.email,
          tokenPrefix: pengurus.tokenPrefix,
        ),
        DemoLoginProfile(
          label: pengelolaInduk.label,
          name: pengelolaInduk.name,
          email: environment.demoPengelolaIndukEmail,
          tokenPrefix: pengelolaInduk.tokenPrefix,
        ),
        DemoLoginProfile(
          label: customer.label,
          name: customer.name,
          email: environment.demoCustomerEmail,
          tokenPrefix: customer.tokenPrefix,
        ),
        DemoLoginProfile(
          label: superadmin.label,
          name: superadmin.name,
          email: environment.demoSuperadminEmail,
          tokenPrefix: superadmin.tokenPrefix,
        ),
      ];
}
