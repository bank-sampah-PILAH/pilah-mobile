import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRepository {
  Future<Either<NetworkException, HalamanNasabah>> getNasabah({
    int page,
    String status,
    String? search,
  });
  Future<Either<NetworkException, HalamanNasabah>> getActiveNasabah();
  Future<Either<NetworkException, NasabahRingkasan>> getNasabahRingkasan(
      String id);
  Future<Either<NetworkException, NasabahEntity>> addNasabah(
      NasabahRequest request);
  Future<Either<NetworkException, NasabahEntity>> updateNasabah(
    String id,
    NasabahRequest request,
  );
  Future<Either<NetworkException, void>> activateNasabah(String id);
  Future<Either<NetworkException, void>> deactivateNasabah(String id);
  Future<Either<NetworkException, void>> approveNasabah(
    String id, {
    String? catatan,
  });
  Future<Either<NetworkException, void>> rejectNasabah(
    String id, {
    String? catatan,
  });
}
