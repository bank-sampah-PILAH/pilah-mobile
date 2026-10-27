import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/pencairan.dart';
import '../model/revisi_pencairan.dart';
import '../model/riwayat_pencairan_filter.dart';

abstract class PencairanRepository {
  Future<Either<NetworkException, List<Pencairan>>> getRiwayat(
    RiwayatPencairanFilter filter,
  );
  Future<Either<NetworkException, Pencairan>> editPencairan(
    EditPencairanRequest request,
  );
  Future<Either<NetworkException, RiwayatRevisiPencairan>> getRevisi(
    String id,
  );
}
