import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/constants/secrets.dart';
import 'package:injectable/injectable.dart';

abstract class AppEnvironment {
  String get baseUrl;

  bool get supportsDemoLogin;

  String get demoOperatorEmail;

  String get demoPengelolaIndukEmail;

  String get demoCustomerEmail;

  /// Always unregistered, unlike [demoCustomerEmail] — for trying the
  /// self-registration flow on demand.
  String get demoNewNasabahEmail;

  String get demoSuperadminEmail;
}

@Injectable(env: [AppKey.devEnv], as: AppEnvironment)
class DevEnvironment implements AppEnvironment {
  @override
  String get baseUrl => Secret.baseUrlDev;

  @override
  bool get supportsDemoLogin => !kReleaseMode && Secret.demoLoginEnabled;

  @override
  String get demoOperatorEmail => Secret.demoOperatorEmail;

  @override
  String get demoPengelolaIndukEmail => Secret.demoPengelolaIndukEmail;

  @override
  String get demoCustomerEmail => Secret.demoCustomerEmail;

  @override
  String get demoNewNasabahEmail => Secret.demoNewNasabahEmail;

  @override
  String get demoSuperadminEmail => Secret.demoSuperadminEmail;
}

@Injectable(env: [AppKey.prodEnv], as: AppEnvironment)
class ProdEnvironment implements AppEnvironment {
  @override
  String get baseUrl => Secret.baseUrlProd;

  @override
  bool get supportsDemoLogin => false;

  @override
  String get demoOperatorEmail => '';

  @override
  String get demoPengelolaIndukEmail => '';

  @override
  String get demoCustomerEmail => '';

  @override
  String get demoNewNasabahEmail => '';

  @override
  String get demoSuperadminEmail => '';
}
