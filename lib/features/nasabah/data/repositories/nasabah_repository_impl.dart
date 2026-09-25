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
  Future<Either<NetworkException, NasabahPage>> getNasabah({
    int page = 1,
    String status = 'aktif',
    String? search,
  }) {
    return apiCall<NasabahPage>(
      func: remoteDataSource.getNasabah(
        page: page,
        status: status,
        search: search,
      ),
      mapper: (result) => result as NasabahPage,
    );
  }

  @override
  Future<Either<NetworkException, NasabahPage>> getActiveNasabah() {
    return apiCall<NasabahPage>(
      func: remoteDataSource.getActiveNasabah(),
      mapper: (result) => result as NasabahPage,
    );
  }

  @override
  Future<Either<NetworkException, NasabahRingkasan>> getNasabahRingkasan(
      String id) {
    return apiCall<NasabahRingkasan>(
      func: remoteDataSource.getNasabahRingkasan(id),
      mapper: (result) => result as NasabahRingkasan,
    );
  }

  @override
  Future<Either<NetworkException, NasabahEntity>> addNasabah(
      NasabahRequest request) {
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

  @override
  Future<Either<NetworkException, void>> approveNasabah(
    String id, {
    String? catatan,
  }) async {
    try {
      await remoteDataSource.approveNasabah(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> rejectNasabah(
    String id, {
    String? catatan,
  }) async {
    try {
      await remoteDataSource.rejectNasabah(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
