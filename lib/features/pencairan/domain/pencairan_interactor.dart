import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'model/pencairan.dart';
import 'repository/pencairan_repository.dart';
import 'use_cases/pencairan_use_cases.dart';

@LazySingleton(as: PencairanUseCases)
class PencairanInteractor implements PencairanUseCases {
  final PencairanRepository _repository;
  const PencairanInteractor(this._repository);

  @override
  Future<Either<NetworkException, int>> getSaldo(String nasabahId) =>
      _repository.getSaldo(nasabahId);

  @override
  Future<Either<NetworkException, Pencairan>> createPencairan(
    PencairanRequest request,
  ) =>
      _repository.createPencairan(request);
}
