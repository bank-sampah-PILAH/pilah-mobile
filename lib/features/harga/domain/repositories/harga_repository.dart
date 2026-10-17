import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';

abstract class HargaRepository {
  Future<Either<NetworkException, List<HargaEntity>>> getHarga();
  Future<Either<NetworkException, void>> addHarga(HargaEntity harga);
  Future<Either<NetworkException, void>> updateHarga(HargaEntity harga);
  Future<Either<NetworkException, void>> deactivateHarga(String id);
  Future<Either<NetworkException, void>> activateHarga(String id);
  Future<Either<NetworkException, void>> ubahHarga(UbahHarga perubahan);
}
