import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/laporan/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/laporan/domain/repositories/transaksi_repository.dart';

@lazySingleton
class AddTransaksiUseCase implements UseCase<void, TransaksiEntity> {
  final TransaksiRepository repository;

  AddTransaksiUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([TransaksiEntity? args]) {
    return repository.addTransaksi(args!);
  }
}
