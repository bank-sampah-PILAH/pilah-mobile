import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'local/pencairan_local_data_sources.dart';
import 'model/mapper/pencairan_mapper.dart';
import 'remote/pencairan_remote_data_sources.dart';
import '../domain/model/pencairan.dart';
import '../domain/repository/pencairan_repository.dart';

@LazySingleton(as: PencairanRepository)
class PencairanRepositoryImpl implements PencairanRepository {
  final PencairanRemoteDataSources _remote;
  final PencairanLocalDataSources _local;

  const PencairanRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<NetworkException, Pencairan>> getSomething() {
    return apiCall<Pencairan>(
      func: _remote.getSomething(),
      mapper: (value) => PencairanMapper.mapResponseToDomain(value),
    );
  }
}
