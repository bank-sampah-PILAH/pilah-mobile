import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/laporan/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/laporan/domain/repositories/transaksi_repository.dart';

@lazySingleton
class GetTransaksiUseCase implements UseCase<List<TransaksiGroupEntity>, void> {
  final TransaksiRepository repository;

  GetTransaksiUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> execute([void args]) {
    return repository.getTransaksi();
  }
}
