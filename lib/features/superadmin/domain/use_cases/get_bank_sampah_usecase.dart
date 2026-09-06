import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/domain/repositories/superadmin_repository.dart';

@lazySingleton
class GetBankSampahUseCase implements UseCase<List<BankSampahEntity>, String> {
  final SuperadminRepository repository;

  GetBankSampahUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<BankSampahEntity>>> execute(
      [String? args]) {
    return repository.getBankSampah(args ?? 'pending');
  }
}
