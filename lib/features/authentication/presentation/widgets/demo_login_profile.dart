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
  static const operator = DemoLoginProfile(
    label: 'Operator aktif',
    name: 'Operator PILAH E2E',
    email: 'operator.demo@example.com',
    tokenPrefix: 'dev',
  );

  static const pendingOperator = DemoLoginProfile(
    label: 'Operator menunggu persetujuan',
    name: 'Operator Pending PILAH E2E',
    email: 'pending.operator.demo@example.com',
    tokenPrefix: 'dev',
  );

  static const customer = DemoLoginProfile(
    label: 'Nasabah',
    name: 'Nasabah PILAH E2E',
    email: 'customer.demo@example.com',
    tokenPrefix: 'dev-nasabah',
  );

  static const superadmin = DemoLoginProfile(
    label: 'Superadmin',
    name: 'Superadmin PILAH E2E',
    email: 'superadmin.demo@example.com',
    tokenPrefix: 'dev-superadmin',
  );

  static const induk = DemoLoginProfile(
    label: 'Pengelola Bank Sampah Induk',
    name: 'Pengelola Induk PILAH E2E',
    email: 'induk.demo@example.com',
    tokenPrefix: 'dev-pengelola-induk',
  );

  static const all = <DemoLoginProfile>[
    operator,
    pendingOperator,
    customer,
    induk,
    superadmin,
  ];

  static List<DemoLoginProfile> forEnvironment(AppEnvironment environment) => [
        DemoLoginProfile(
          label: operator.label,
          name: operator.name,
          email: environment.demoOperatorEmail,
          tokenPrefix: operator.tokenPrefix,
        ),
        DemoLoginProfile(
          label: pendingOperator.label,
          name: pendingOperator.name,
          email: environment.demoPendingOperatorEmail,
          tokenPrefix: pendingOperator.tokenPrefix,
        ),
        DemoLoginProfile(
          label: customer.label,
          name: customer.name,
          email: environment.demoCustomerEmail,
          tokenPrefix: customer.tokenPrefix,
        ),
        DemoLoginProfile(
          label: induk.label,
          name: induk.name,
          email: environment.demoIndukEmail,
          tokenPrefix: induk.tokenPrefix,
        ),
        DemoLoginProfile(
          label: superadmin.label,
          name: superadmin.name,
          email: environment.demoSuperadminEmail,
          tokenPrefix: superadmin.tokenPrefix,
        ),
      ];
}
