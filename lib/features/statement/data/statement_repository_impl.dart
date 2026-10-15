import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import 'remote/statement_remote_data_sources.dart';
import '../domain/model/statement_export.dart';
import '../domain/repository/statement_repository.dart';

@LazySingleton(as: StatementRepository)
class StatementRepositoryImpl implements StatementRepository {
  final StatementRemoteDataSources _remote;

  const StatementRepositoryImpl(this._remote);

  @override
  Future<Either<NetworkException, StatementExport>> exportPdf(
    String membershipId,
  ) {
    return apiCall<StatementExport>(
      func: _remote.exportPdf(membershipId),
      mapper: (value) => value as StatementExport,
    );
  }
}
