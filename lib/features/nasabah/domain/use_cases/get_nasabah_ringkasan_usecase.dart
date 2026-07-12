import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@lazySingleton
class GetNasabahRingkasanUseCase implements UseCase<NasabahRingkasan, String> {
  final NasabahRepository repository;

  GetNasabahRingkasanUseCase(this.repository);

  @override
  Future<Either<NetworkException, NasabahRingkasan>> execute([String? args]) {
    return repository.getNasabahRingkasan(args!);
  }
}
