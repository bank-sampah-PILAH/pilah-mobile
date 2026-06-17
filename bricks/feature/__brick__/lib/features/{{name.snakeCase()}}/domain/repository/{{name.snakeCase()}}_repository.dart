import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/{{name.snakeCase()}}.dart';

abstract class {{name.pascalCase()}}Repository {
  Future<Either<NetworkException, {{name.pascalCase()}}>> getSomething();
}
