import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';

@lazySingleton
class GetHargaUseCase implements UseCase<List<HargaEntity>, void> {
  final HargaRepository repository;

  GetHargaUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<HargaEntity>>> execute([void args]) {
    return repository.getHarga();
  }
}
