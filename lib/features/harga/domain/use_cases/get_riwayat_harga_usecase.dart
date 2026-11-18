import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';

@lazySingleton
class GetRiwayatHargaUseCase implements UseCase<List<VersiHarga>, String> {
  final HargaRepository repository;

  GetRiwayatHargaUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<VersiHarga>>> execute([String? args]) {
    return repository.getRiwayatHarga(args!);
  }
}
