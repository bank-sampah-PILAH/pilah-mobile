import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Secret {
  static String get baseUrlDev => dotenv.env['BASE_URL_DEV'] ?? '';
  static String get baseUrlProd => dotenv.env['BASE_URL_PROD'] ?? '';

  static bool get demoLoginEnabled =>
      (dotenv.env['ENABLE_DEMO_LOGIN'] ?? 'false').toLowerCase() == 'true';

  static String get demoOperatorEmail =>
      dotenv.env['DEMO_OPERATOR_EMAIL'] ?? 'pengurus.demo@example.com';

  static String get demoPengelolaIndukEmail =>
      dotenv.env['DEMO_PENGELOLA_INDUK_EMAIL'] ?? 'induk.demo@example.com';

  static String get demoCustomerEmail =>
      dotenv.env['DEMO_CUSTOMER_EMAIL'] ?? 'nasabah.demo@example.com';

  static String get demoIndukEmail =>
      dotenv.env['DEMO_INDUK_EMAIL'] ?? 'induk.demo@example.com';

  static String get demoSuperadminEmail =>
      dotenv.env['DEMO_SUPERADMIN_EMAIL'] ?? 'superadmin.demo@example.com';
}
