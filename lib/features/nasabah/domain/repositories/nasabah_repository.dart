import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRepository {
  Future<Either<NetworkException, List<NasabahEntity>>> getNasabah();
  Future<Either<NetworkException, void>> activateNasabah(String id);
  Future<Either<NetworkException, void>> deactivateNasabah(String id);
}
