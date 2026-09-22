import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/pencairan.dart';
import '../model/riwayat_pencairan_filter.dart';

abstract class PencairanRepository {
  Future<Either<NetworkException, int>> getSaldo(String nasabahId);
  Future<Either<NetworkException, Pencairan>> createPencairan(
    PencairanRequest request,
  );
  Future<Either<NetworkException, List<Pencairan>>> getRiwayat(
    RiwayatPencairanFilter filter,
  );
}
