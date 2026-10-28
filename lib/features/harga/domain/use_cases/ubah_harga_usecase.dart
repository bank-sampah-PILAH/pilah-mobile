import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';

@lazySingleton
class UbahHargaUseCase implements UseCase<void, UbahHarga> {
  final HargaRepository repository;

  UbahHargaUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([UbahHarga? args]) {
    return repository.ubahHarga(args!);
  }
}
