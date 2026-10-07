import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../domain/model/draft_pencairan.dart';
import '../domain/repository/draft_pencairan_repository.dart';
import 'remote/draft_pencairan_remote_data_source.dart';

@LazySingleton(as: DraftPencairanRepository)
class DraftPencairanRepositoryImpl implements DraftPencairanRepository {
  final DraftPencairanRemoteDataSource _remote;
  const DraftPencairanRepositoryImpl(this._remote);

  @override
  Future<Either<NetworkException, List<Kandidat>>> getKandidat({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    int saldoMin = 0,
  }) =>
      apiCall<List<Kandidat>>(
        func: _remote.getKandidat(
            search: search, urutan: urutan, saldoMin: saldoMin),
        mapper: (value) => value as List<Kandidat>,
      );

  @override
  Future<Either<NetworkException, List<DraftRingkasan>>> getDrafts() =>
      apiCall<List<DraftRingkasan>>(
        func: _remote.getDrafts(),
        mapper: (value) => value as List<DraftRingkasan>,
      );

  @override
  Future<Either<NetworkException, DraftPencairan>> getDraft(String id) =>
      _draft(_remote.getDraft(id));

  @override
  Future<Either<NetworkException, DraftPencairan>> createDraft(
    DraftInput input,
  ) =>
      _draft(_remote.createDraft(input));

  @override
  Future<Either<NetworkException, DraftPencairan>> updateDraft(
    String id,
    DraftInput input,
  ) =>
      _draft(_remote.updateDraft(id, input));

  @override
  Future<Either<NetworkException, DraftPencairan>> cancelDraft(String id) =>
      _draft(_remote.cancelDraft(id));

  Future<Either<NetworkException, DraftPencairan>> _draft(
    Future<DraftPencairan> call,
  ) =>
      apiCall<DraftPencairan>(
        func: call,
        mapper: (value) => value as DraftPencairan,
      );
}
