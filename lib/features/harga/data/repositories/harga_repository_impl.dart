import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_local_data_source.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';

@LazySingleton(as: HargaRepository)
class HargaRepositoryImpl implements HargaRepository {
  final HargaLocalDataSource localDataSource;

  HargaRepositoryImpl(this.localDataSource);

  @override
  Future<Either<NetworkException, List<HargaEntity>>> getHarga() async {
    try {
      final result = await localDataSource.getHarga();
      return Right(result);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> addHarga(HargaEntity harga) async {
    try {
      final model = HargaModel(
        id: harga.id,
        name: harga.name,
        price: harga.price,
        priceFormatted: harga.priceFormatted,
        category: harga.category,
        subtitle: harga.subtitle,
        badgeText: harga.badgeText,
        icon: harga.icon,
        iconColor: harga.iconColor,
        isActive: harga.isActive,
      );
      await localDataSource.addHarga(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> updateHarga(HargaEntity harga) async {
    try {
      final model = HargaModel(
        id: harga.id,
        name: harga.name,
        price: harga.price,
        priceFormatted: harga.priceFormatted,
        category: harga.category,
        subtitle: harga.subtitle,
        badgeText: harga.badgeText,
        icon: harga.icon,
        iconColor: harga.iconColor,
        isActive: harga.isActive,
      );
      await localDataSource.updateHarga(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> deactivateHarga(String id) async {
    try {
      await localDataSource.deactivateHarga(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
