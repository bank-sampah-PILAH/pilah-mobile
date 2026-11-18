import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

/// Legacy one-page snapshot of active nasabah.
///
/// Paginated consumers, including the setoran picker, should use
/// [GetNasabahUseCase] with `status: 'aktif'`.
@lazySingleton
class GetActiveNasabahUseCase implements UseCase<HalamanNasabah, void> {
  final NasabahRepository repository;

  GetActiveNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, HalamanNasabah>> execute([void args]) {
    return repository.getActiveNasabah();
  }
}
