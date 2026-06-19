import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_local_data_source.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@LazySingleton(as: NasabahRepository)
class NasabahRepositoryImpl implements NasabahRepository {
  final NasabahLocalDataSource localDataSource;

  NasabahRepositoryImpl(this.localDataSource);

  @override
  Future<Either<NetworkException, List<NasabahEntity>>> getNasabah() async {
    try {
      final result = await localDataSource.getNasabah();
      return Right(result);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> activateNasabah(String id) async {
    try {
      await localDataSource.activateNasabah(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> deactivateNasabah(String id) async {
    try {
      await localDataSource.deactivateNasabah(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
