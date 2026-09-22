import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'model/mapper/pencairan_mapper.dart';
import 'model/responses/pencairan_response.dart';
import 'remote/pencairan_remote_data_sources.dart';
import '../domain/model/pencairan.dart';
import '../domain/repository/pencairan_repository.dart';

@LazySingleton(as: PencairanRepository)
class PencairanRepositoryImpl implements PencairanRepository {
  final PencairanRemoteDataSources _remote;

  const PencairanRepositoryImpl(this._remote);

  @override
  Future<Either<NetworkException, int>> getSaldo(String nasabahId) {
    return apiCall<int>(
      func: _remote.getSaldo(nasabahId),
      mapper: (value) => value as int,
    );
  }

  @override
  Future<Either<NetworkException, Pencairan>> createPencairan(
    PencairanRequest request,
  ) {
    return apiCall<Pencairan>(
      func: _remote.createPencairan(request),
      mapper: (value) =>
          PencairanMapper.mapResponseToDomain(value as PencairanResponse),
    );
  }
}
