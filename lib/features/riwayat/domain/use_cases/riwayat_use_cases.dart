import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';

/// Loads one page of the nasabah's setoran riwayat.
@lazySingleton
class GetRiwayatHistoryUseCase
    implements UseCase<RiwayatHistory, RiwayatHistoryParams> {
  final RiwayatRepository repository;

  GetRiwayatHistoryUseCase(this.repository);

  @override
  Future<Either<NetworkException, RiwayatHistory>> execute(
      [RiwayatHistoryParams? args]) {
    final params = args ?? const RiwayatHistoryParams('', page: 1);
    return repository.history(params.membershipId, page: params.page);
  }
}

class RiwayatHistoryParams {
  final String membershipId;
  final int page;

  const RiwayatHistoryParams(this.membershipId, {this.page = 1});
}

/// Loads one setoran's itemized detail.
@lazySingleton
class GetRiwayatSetoranDetailUseCase
    implements UseCase<RiwayatSetoranDetail, RiwayatSetoranDetailParams> {
  final RiwayatRepository repository;

  GetRiwayatSetoranDetailUseCase(this.repository);

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> execute(
      [RiwayatSetoranDetailParams? args]) {
    final params = args ??
        const RiwayatSetoranDetailParams(membershipId: '', transactionId: '');
    return repository.setoranDetail(params.membershipId, params.transactionId);
  }
}

class RiwayatSetoranDetailParams {
  final String membershipId;
  final String transactionId;

  const RiwayatSetoranDetailParams(
      {required this.membershipId, required this.transactionId});
}
