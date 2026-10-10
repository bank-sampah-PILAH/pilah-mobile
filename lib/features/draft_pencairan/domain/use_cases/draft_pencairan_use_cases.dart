import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../model/draft_pencairan.dart';

abstract class DraftPencairanUseCases {
  Future<Either<NetworkException, List<Kandidat>>> getKandidat({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    int saldoMin = 0,
    bool termasukKosong = false,
  });
  Future<Either<NetworkException, List<DraftRingkasan>>> getDrafts();
  Future<Either<NetworkException, DraftPencairan>> getDraft(String id);
  Future<Either<NetworkException, DraftPencairan>> createDraft(
      DraftInput input);
  Future<Either<NetworkException, DraftPencairan>> updateDraft(
    String id,
    DraftInput input,
  );
  Future<Either<NetworkException, DraftPencairan>> cancelDraft(String id);
  Future<Either<NetworkException, DraftPencairan>> confirmDraft(String id);

  /// The export of [input] as it is now, saved or not; nothing is stored.
  Future<Either<NetworkException, DraftExport>> exportPratinjau(
    DraftInput input,
    ExportBerkas berkas,
  );
  Future<Either<NetworkException, DraftExport>> exportDraft(
    String id,
    ExportBerkas berkas,
  );
}
