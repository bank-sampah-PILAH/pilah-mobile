import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/pencairan.dart';

abstract class PencairanUseCases {
  Future<Either<NetworkException, Pencairan>> getSomething();
}
