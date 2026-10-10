import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import 'model/draft_pencairan.dart';
import 'repository/draft_pencairan_repository.dart';
import 'use_cases/draft_pencairan_use_cases.dart';

@LazySingleton(as: DraftPencairanUseCases)
class DraftPencairanInteractor implements DraftPencairanUseCases {
  final DraftPencairanRepository _repository;
  const DraftPencairanInteractor(this._repository);

  @override
  Future<Either<NetworkException, List<Kandidat>>> getKandidat({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    int saldoMin = 0,
    bool termasukKosong = false,
  }) =>
      _repository.getKandidat(
        search: search,
        urutan: urutan,
        saldoMin: saldoMin,
        termasukKosong: termasukKosong,
      );

  @override
  Future<Either<NetworkException, List<DraftRingkasan>>> getDrafts() =>
      _repository.getDrafts();

  @override
  Future<Either<NetworkException, DraftPencairan>> getDraft(String id) =>
      _repository.getDraft(id);

  @override
  Future<Either<NetworkException, DraftPencairan>> createDraft(
    DraftInput input,
  ) =>
      _repository.createDraft(input);

  @override
  Future<Either<NetworkException, DraftPencairan>> updateDraft(
    String id,
    DraftInput input,
  ) =>
      _repository.updateDraft(id, input);

  @override
  Future<Either<NetworkException, DraftPencairan>> cancelDraft(String id) =>
      _repository.cancelDraft(id);
}
