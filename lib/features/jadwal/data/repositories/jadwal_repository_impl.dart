import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_page_model.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';

@LazySingleton(as: JadwalRepository)
class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource remoteDataSource;

  JadwalRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, JadwalEntity>> getDetail(String id) async {
    try {
      return Right(await remoteDataSource.getDetail(id));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  @override
  Future<Either<NetworkException, JadwalPageResult>> getJadwal({
    required int page,
    DateTime? date,
    DateTime? dateTo,
    String? membershipId,
  }) async {
    try {
      final response = await _requestPage(
        page: page,
        date: date,
        dateTo: dateTo,
        membershipId: membershipId,
      );
      return Right(JadwalPageResult(
        items: response.items,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
      ));
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    }
  }

  /// Argumen opsional yang kosong **tidak dikirim**, bukan dikirim bernilai
  /// null, sehingga panggilan sisi pengurus tetap sama persis seperti sebelum
  /// keanggotaan ikut dibawa dan stub pengujian yang ada tidak ikut berubah.
  Future<JadwalPageModel> _requestPage({
    required int page,
    DateTime? date,
    DateTime? dateTo,
    String? membershipId,
  }) {
    if (dateTo == null) {
      return membershipId == null
          ? remoteDataSource.getJadwal(page: page, date: date)
          : remoteDataSource.getJadwal(
              page: page,
              date: date,
              membershipId: membershipId,
            );
    }
    return membershipId == null
        ? remoteDataSource.getJadwal(page: page, date: date, dateTo: dateTo)
        : remoteDataSource.getJadwal(
            page: page,
            date: date,
            dateTo: dateTo,
            membershipId: membershipId,
          );
  }

  @override
  Future<Either<NetworkException, Set<DateTime>>> getCalendarDates(
    DateTime startDate,
    DateTime endDate, {
    String? membershipId,
  }) async {
    try {
      return Right(membershipId == null
          ? await remoteDataSource.getCalendarDates(startDate, endDate)
          : await remoteDataSource.getCalendarDates(
              startDate,
              endDate,
              membershipId: membershipId,
            ));
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
