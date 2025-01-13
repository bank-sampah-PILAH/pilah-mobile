import 'package:boilerplate/core/constants/app_key.dart';
import 'package:boilerplate/core/constants/secrets.dart';
import 'package:injectable/injectable.dart';

abstract class AppEnvironment {
  String get baseUrl;
}

@Injectable(env: [AppKey.devEnv], as: AppEnvironment)
class DevEnvironment implements AppEnvironment {
  @override
  String get baseUrl => Secret.baseUrlDev;
}

@Injectable(env: [AppKey.prodEnv], as: AppEnvironment)
class ProdEnvironment implements AppEnvironment {
  @override
  String get baseUrl => Secret.baseUrlProd;
}