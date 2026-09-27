import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

abstract class BankSampahApprovalRepository {
  Future<Either<NetworkException, List<NasabahMembershipEntity>>>
      getMemberships();

  Future<Either<NetworkException, void>> appeal(String bankSampahId);
}
