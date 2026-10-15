import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import 'model/statement_export.dart';
import 'repository/statement_repository.dart';
import 'use_cases/statement_use_cases.dart';

@LazySingleton(as: StatementUseCases)
class StatementInteractor implements StatementUseCases {
  final StatementRepository _repository;
  const StatementInteractor(this._repository);

  @override
  Future<Either<NetworkException, StatementExport>> exportPdf(
          String membershipId) =>
      _repository.exportPdf(membershipId);
}
