import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_model.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_page_result.dart';
import 'package:pilah_mobile/features/pengumuman/domain/repositories/pengumuman_repository.dart';

@LazySingleton(as: PengumumanRepository)
class PengumumanRepositoryImpl implements PengumumanRepository {
  final PengumumanRemoteDataSource remoteDataSource;

  PengumumanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, PengumumanPageResult>> getPengumuman({
    required int page,
    String? status,
  }) async {
    try {
      final response =
          await remoteDataSource.getPengumuman(page: page, status: status);
      return Right(PengumumanPageResult(
        items: response.items,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
      ));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, PengumumanEntity>> createPengumuman(
      PengumumanEntity pengumuman) async {
    try {
      return Right(await remoteDataSource
          .createPengumuman(PengumumanModel.fromEntity(pengumuman)));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, PengumumanEntity>> updatePengumuman(
      PengumumanEntity pengumuman) async {
    try {
      return Right(await remoteDataSource
          .updatePengumuman(PengumumanModel.fromEntity(pengumuman)));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, PengumumanEntity>> terbitkan(
    String id, {
    DateTime? terbitPada,
    DateTime? masaBerlakuHingga,
  }) async {
    try {
      return Right(await remoteDataSource.terbitkan(
        id,
        terbitPada: terbitPada,
        masaBerlakuHingga: masaBerlakuHingga,
      ));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, PengumumanEntity>> tarik(String id) async {
    try {
      return Right(await remoteDataSource.tarik(id));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, void>> deletePengumuman(String id) async {
    try {
      return Right(await remoteDataSource.deletePengumuman(id));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }
}
