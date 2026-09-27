import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';

@lazySingleton
class GetNasabahMembershipsUseCase
    implements UseCase<List<NasabahMembershipEntity>, void> {
  final BankSampahApprovalRepository repository;

  GetNasabahMembershipsUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<NasabahMembershipEntity>>> execute(
      [void args]) {
    return repository.getMemberships();
  }
}
