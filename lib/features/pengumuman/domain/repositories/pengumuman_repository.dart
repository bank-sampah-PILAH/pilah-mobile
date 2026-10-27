import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_page_result.dart';

abstract class PengumumanRepository {
  Future<Either<NetworkException, PengumumanPageResult>> getPengumuman({
    required int page,
    String? status,
  });
  Future<Either<NetworkException, PengumumanEntity>> createPengumuman(
      PengumumanEntity pengumuman);
  Future<Either<NetworkException, PengumumanEntity>> updatePengumuman(
      PengumumanEntity pengumuman);
  Future<Either<NetworkException, PengumumanEntity>> terbitkan(
    String id, {
    DateTime? terbitPada,
    DateTime? masaBerlakuHingga,
  });
  Future<Either<NetworkException, PengumumanEntity>> tarik(String id);
  Future<Either<NetworkException, void>> deletePengumuman(String id);
}
