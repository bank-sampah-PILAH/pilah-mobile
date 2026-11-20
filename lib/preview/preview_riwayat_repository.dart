import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';

/// Offline history fixture; PDF export uses the statement pipeline.
class PreviewRiwayatRepository implements RiwayatRepository {
  PreviewRiwayatRepository(this.source);
  final NasabahRepository source;

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(String membershipId,
          {int page = 1}) async =>
      const Right(RiwayatHistory([], false));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
          String membershipId, String transactionId) async =>
      Left(NetworkException(message: 'Pratinjau tidak memiliki data detail.'));
}
