import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

class UpdateNasabahParams {
  final String id;
  final NasabahRequest request;

  UpdateNasabahParams({required this.id, required this.request});
}

@lazySingleton
class UpdateNasabahUseCase implements UseCase<NasabahEntity, UpdateNasabahParams> {
  final NasabahRepository repository;

  UpdateNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, NasabahEntity>> execute([UpdateNasabahParams? args]) {
    return repository.updateNasabah(args!.id, args.request);
  }
}
