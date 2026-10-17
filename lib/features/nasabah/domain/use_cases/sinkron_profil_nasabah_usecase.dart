import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

/// Menyamakan catatan bank sampah sebuah nasabah dengan profil yang diisikan
/// nasabah itu sendiri pada akunnya.
@lazySingleton
class SinkronProfilNasabahUseCase implements UseCase<void, String> {
  final NasabahRepository repository;

  SinkronProfilNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([String? args]) {
    return repository.sinkronProfilNasabah(args!);
  }
}
