import 'package:boilerplate/core/client/network_service.dart';
import 'package:boilerplate/core/client/network_utils.dart';
import 'package:boilerplate/core/constants/secrets.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'di.config.dart';

final di = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
void configureDependencies({required String environment}) {
  di.init(environment: environment);
}
