import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'model/mapper/pencairan_mapper.dart';
import 'model/responses/pencairan_response.dart';
import 'remote/pencairan_remote_data_sources.dart';
import '../domain/model/pencairan.dart';
import '../domain/model/riwayat_pencairan_filter.dart';
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

  @override
  Future<Either<NetworkException, List<Pencairan>>> getRiwayat(
    RiwayatPencairanFilter filter,
  ) {
    return apiCall<List<Pencairan>>(
      func: _remote.getRiwayat(filter),
      mapper: (value) => (value as List<PencairanResponse>)
          .map(PencairanMapper.mapResponseToDomain)
          .toList(),
    );
  }

  @override
  Future<Either<NetworkException, Pencairan>> editPencairan(
    EditPencairanRequest request,
  ) {
    return apiCall<Pencairan>(
      func: _remote.editPencairan(request),
      mapper: (value) =>
          PencairanMapper.mapResponseToDomain(value as PencairanResponse),
    );
  }
}
