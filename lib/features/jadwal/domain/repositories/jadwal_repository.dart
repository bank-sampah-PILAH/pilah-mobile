import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';

abstract class JadwalRepository {
  Future<Either<NetworkException, JadwalPageResult>> getJadwal({
    required int page,
    DateTime? date,
  });
  Future<Either<NetworkException, Set<DateTime>>> getCalendarDates(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<NetworkException, JadwalEntity>> createJadwal(
      JadwalEntity jadwal);
  Future<Either<NetworkException, JadwalEntity>> updateJadwal(
      JadwalEntity jadwal);
  Future<Either<NetworkException, JadwalEntity>> transition(
      String id, String action);
}
