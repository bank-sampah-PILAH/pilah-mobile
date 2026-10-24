import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../model/statement_export.dart';

abstract class StatementUseCases {
  Future<Either<NetworkException, StatementExport>> exportPdf(
    String membershipId,
  );
}
