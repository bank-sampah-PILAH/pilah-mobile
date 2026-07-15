import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@lazySingleton
class ResendWaUseCase implements UseCase<String, String> {
  final TransaksiRepository repository;

  ResendWaUseCase(this.repository);

  @override
  Future<Either<NetworkException, String>> execute([String? args]) {
    return repository.resendWa(args!);
  }
}
