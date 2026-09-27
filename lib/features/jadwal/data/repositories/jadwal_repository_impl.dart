import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';

@LazySingleton(as: JadwalRepository)
class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource remoteDataSource;

  JadwalRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, JadwalPageResult>> getJadwal({
    required int page,
    DateTime? date,
  }) async {
    try {
      final response = await remoteDataSource.getJadwal(page: page, date: date);
      return Right(JadwalPageResult(
        items: response.items,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
      ));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, Set<DateTime>>> getCalendarDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return Right(await remoteDataSource.getCalendarDates(startDate, endDate));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, JadwalEntity>> createJadwal(
      JadwalEntity jadwal) async {
    try {
      return Right(
          await remoteDataSource.createJadwal(JadwalModel.fromEntity(jadwal)));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, JadwalEntity>> updateJadwal(
      JadwalEntity jadwal) async {
    try {
      return Right(
          await remoteDataSource.updateJadwal(JadwalModel.fromEntity(jadwal)));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, JadwalEntity>> transition(
      String id, String action) async {
    try {
      return Right(await remoteDataSource.transition(id, action));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }
}
