import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@lazySingleton
class AddNasabahUseCase implements UseCase<NasabahEntity, NasabahRequest> {
  final NasabahRepository repository;

  AddNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, NasabahEntity>> execute([NasabahRequest? args]) {
    return repository.addNasabah(args!);
  }
}
