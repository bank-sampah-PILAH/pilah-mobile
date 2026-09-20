import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@lazySingleton
class RejectNasabahUseCase implements UseCase<void, DecideNasabahParams> {
  final NasabahRepository repository;

  RejectNasabahUseCase(this.repository);

  @override
  Future<Either<NetworkException, void>> execute(
      [DecideNasabahParams? args]) {
    return repository.rejectNasabah(args!.id, catatan: args.catatan);
  }
}