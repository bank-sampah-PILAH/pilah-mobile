import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';

@lazySingleton
class ActivateHargaUseCase implements UseCase<void, String> {
  final HargaRepository repository;

  ActivateHargaUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([String? args]) {
    return repository.activateHarga(args!);
  }
}
