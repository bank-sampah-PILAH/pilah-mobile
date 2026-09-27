import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Secret {
  static String get baseUrlDev => dotenv.env['BASE_URL_DEV'] ?? '';
  static String get baseUrlProd => dotenv.env['BASE_URL_PROD'] ?? '';

  static bool get demoLoginEnabled =>
      (dotenv.env['ENABLE_DEMO_LOGIN'] ?? 'false').toLowerCase() == 'true';

  static String get demoPengurusEmail =>
      dotenv.env['DEMO_PENGURUS_EMAIL'] ?? 'pengurus.demo@example.com';

  static String get demoPengelolaIndukEmail =>
      dotenv.env['DEMO_PENGELOLA_INDUK_EMAIL'] ?? 'induk.demo@example.com';

  static String get demoCustomerEmail =>
      dotenv.env['DEMO_CUSTOMER_EMAIL'] ?? 'nasabah.demo@example.com';

  /// Always an unregistered account: unlike [demoCustomerEmail] (seeded with
  /// a completed profile and membership already in place), this one has no
  /// fixture data behind it, so it always lands on complete_profile and the
  /// bank-sampah picker — the self-registration flow, on demand, without
  /// hand-editing .env or the seed script per attempt.
  static String get demoNewNasabahEmail =>
      dotenv.env['DEMO_NEW_NASABAH_EMAIL'] ?? 'nasabah.baru.demo@example.com';

  static String get demoSuperadminEmail =>
      dotenv.env['DEMO_SUPERADMIN_EMAIL'] ?? 'superadmin.demo@example.com';
}
