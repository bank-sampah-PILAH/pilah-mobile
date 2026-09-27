import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/data/datasources/bank_sampah_approval_remote_data_source.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';

@LazySingleton(as: BankSampahApprovalRepository)
class BankSampahApprovalRepositoryImpl implements BankSampahApprovalRepository {
  final BankSampahApprovalRemoteDataSource remoteDataSource;

  BankSampahApprovalRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, List<NasabahMembershipEntity>>>
      getMemberships() {
    return apiCall<List<NasabahMembershipEntity>>(
      func: remoteDataSource.getMemberships(),
      mapper: (result) => (result as List).cast<NasabahMembershipEntity>(),
    );
  }

  @override
  Future<Either<NetworkException, void>> appeal(String bankSampahId) {
    return apiCall<void>(
      func: remoteDataSource.appeal(bankSampahId),
      mapper: (_) {},
    );
  }
}
