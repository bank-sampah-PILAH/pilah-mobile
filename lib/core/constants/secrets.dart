import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Secret {
  static String get baseUrlDev => dotenv.env['BASE_URL_DEV'] ?? '';
  static String get baseUrlProd => dotenv.env['BASE_URL_PROD'] ?? '';
}
