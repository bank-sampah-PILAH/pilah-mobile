import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';

abstract class RiwayatRepository {
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page,
  });
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
    String membershipId,
    String transactionId,
  );
  Future<Either<NetworkException, RiwayatPdf>> exportPdf(String membershipId);
}
