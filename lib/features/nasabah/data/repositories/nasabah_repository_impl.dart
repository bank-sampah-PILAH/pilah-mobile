import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@LazySingleton(as: NasabahRepository)
class NasabahRepositoryImpl implements NasabahRepository {
  final NasabahRemoteDataSource remoteDataSource;

  NasabahRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, List<NasabahEntity>>> getNasabah() {
    return apiCall<List<NasabahEntity>>(
      func: remoteDataSource.getNasabah(),
      mapper: (result) => (result as List).cast<NasabahEntity>(),
    );
  }

  @override
  Future<Either<NetworkException, NasabahRingkasan>> getNasabahRingkasan(String id) {
    return apiCall<NasabahRingkasan>(
      func: remoteDataSource.getNasabahRingkasan(id),
      mapper: (result) => result as NasabahRingkasan,
    );
  }

  @override
  Future<Either<NetworkException, NasabahEntity>> addNasabah(NasabahRequest request) {
    return apiCall<NasabahEntity>(
      func: remoteDataSource.addNasabah(request),
      mapper: (result) => result as NasabahEntity,
    );
  }

  @override
  Future<Either<NetworkException, NasabahEntity>> updateNasabah(
    String id,
    NasabahRequest request,
  ) {
    return apiCall<NasabahEntity>(
      func: remoteDataSource.updateNasabah(id, request),
      mapper: (result) => result as NasabahEntity,
    );
  }

  @override
  Future<Either<NetworkException, void>> activateNasabah(String id) async {
    try {
      await remoteDataSource.setStatus(id, true);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> deactivateNasabah(String id) async {
    try {
      await remoteDataSource.setStatus(id, false);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
