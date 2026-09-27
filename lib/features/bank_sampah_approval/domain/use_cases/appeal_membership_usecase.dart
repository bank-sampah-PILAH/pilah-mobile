import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';

class AppealMembershipParams {
  final String bankSampahId;
  final String pesan;

  const AppealMembershipParams({required this.bankSampahId, this.pesan = ''});
}

@lazySingleton
class AppealMembershipUseCase
    implements UseCase<void, AppealMembershipParams> {
  final BankSampahApprovalRepository repository;

  AppealMembershipUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute(
      [AppealMembershipParams? args]) {
    return repository.appeal(args!.bankSampahId, pesan: args.pesan);
  }
}
