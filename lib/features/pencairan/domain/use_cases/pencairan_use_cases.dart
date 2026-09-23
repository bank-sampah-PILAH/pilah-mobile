import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/pencairan.dart';

abstract class PencairanUseCases {
  Future<Either<NetworkException, int>> getSaldo(String nasabahId);
  Future<Either<NetworkException, Pencairan>> createPencairan(
    PencairanRequest request,
  );
}
