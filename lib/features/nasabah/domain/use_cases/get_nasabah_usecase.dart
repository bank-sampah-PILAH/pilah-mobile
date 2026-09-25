import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@lazySingleton
/// Penyaring satu halaman daftar nasabah (PIL-214).
///
/// [status] memakai kosakata backend: `aktif`, `tidak_aktif`, `menunggu`.
class GetNasabahParams {
  final int page;
  final String status;
  final String? search;

  const GetNasabahParams({
    this.page = 1,
    this.status = 'aktif',
    this.search,
  });
}

class GetNasabahUseCase implements UseCase<HalamanNasabah, GetNasabahParams> {
  final NasabahRepository repository;

  GetNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, HalamanNasabah>> execute([
    GetNasabahParams? args,
  ]) {
    final params = args ?? const GetNasabahParams();
    return repository.getNasabah(
      page: params.page,
      status: params.status,
      search: params.search,
    );
  }
}
