import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';

@lazySingleton
class AppealMembershipUseCase implements UseCase<void, String> {
  final BankSampahApprovalRepository repository;

  AppealMembershipUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([String? args]) {
    return repository.appeal(args!);
  }
}
