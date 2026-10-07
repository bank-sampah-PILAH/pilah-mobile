import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';

@LazySingleton(as: RiwayatRepository)
class RiwayatRepositoryImpl implements RiwayatRepository {
  final RiwayatRemoteDataSource _remote;

  const RiwayatRepositoryImpl(this._remote);

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page = 1,
  }) {
    return apiCall<RiwayatHistory>(
      func: _remote.history(membershipId, page: page),
      mapper: (result) => result as RiwayatHistory,
    );
  }

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
    String membershipId,
    String transactionId,
  ) {
    return apiCall<RiwayatSetoranDetail>(
      func: _remote.setoranDetail(membershipId, transactionId),
      mapper: (result) => result as RiwayatSetoranDetail,
    );
  }

  @override
  Future<Either<NetworkException, RiwayatPdf>> exportPdf(
    String membershipId,
  ) {
    return apiCall<RiwayatPdf>(
      func: _remote.exportPdf(membershipId),
      mapper: (result) => result as RiwayatPdf,
    );
  }
}
