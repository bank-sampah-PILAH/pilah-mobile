import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../model/statement_export.dart';

abstract class StatementRepository {
  /// Downloads the nasabah activity-statement PDF (PIL-315) for one
  /// membership. The 400 "no data" case comes back as a [NetworkException]
  /// carrying the backend message.
  Future<Either<NetworkException, StatementExport>> exportPdf(
    String membershipId,
  );
}