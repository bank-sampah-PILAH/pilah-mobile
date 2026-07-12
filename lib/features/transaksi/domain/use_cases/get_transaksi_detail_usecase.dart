import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@lazySingleton
class GetTransaksiDetailUseCase implements UseCase<TransaksiDetailEntity, String> {
  final TransaksiRepository repository;

  GetTransaksiDetailUseCase(this.repository);

  @override
  Future<Either<NetworkException, TransaksiDetailEntity>> execute([String? args]) {
    return repository.getTransaksiDetail(args!);
  }
}
