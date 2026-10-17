import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import '../entities/aktivitas_page.dart';
import '../entities/transaksi_filter.dart';
import '../repositories/aktivitas_repository.dart';
export '../entities/aktivitas_page.dart';

@lazySingleton
class GetAktivitasUseCase implements UseCase<AktivitasPage, TransaksiFilter> {
  GetAktivitasUseCase(this.repository);
  final AktivitasRepository repository;
  @override
  Future<Either<NetworkException, AktivitasPage>> execute(
          [TransaksiFilter? args]) =>
      repository.history(args ?? const TransaksiFilter());
}
