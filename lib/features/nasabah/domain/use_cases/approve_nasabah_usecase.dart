import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

/// Id + optional catatan for an approve/reject decision (PIL-188).
class DecideNasabahParams {
  final String id;
  final String? catatan;

  DecideNasabahParams({required this.id, this.catatan});
}

@lazySingleton
class ApproveNasabahUseCase implements UseCase<void, DecideNasabahParams> {
  final NasabahRepository repository;

  ApproveNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute([DecideNasabahParams? args]) {
    return repository.approveNasabah(args!.id, catatan: args.catatan);
  }
}
