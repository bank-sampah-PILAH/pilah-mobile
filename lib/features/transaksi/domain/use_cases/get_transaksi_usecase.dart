import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@lazySingleton
class GetTransaksiUseCase implements UseCase<List<TransaksiGroupEntity>, TransaksiFilter> {
  final TransaksiRepository repository;

  GetTransaksiUseCase(this.repository);

  @override
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> execute([TransaksiFilter? args]) {
    return repository.getTransaksi(args ?? const TransaksiFilter());
  }
}
