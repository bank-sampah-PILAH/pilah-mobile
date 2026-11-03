import '../entities/bulk_void_result.dart';
import '../entities/transaksi_entity.dart';
import 'batalkan_transaksi_usecase.dart';

/// Compose PIL-428's existing operation. Each call owns its server transaction;
/// a refusal does not roll back earlier successes or duplicate saldo logic here.
class BatalkanBeberapaTransaksiUseCase {
  const BatalkanBeberapaTransaksiUseCase(this._batalkan);
  final BatalkanTransaksiUseCase _batalkan;

  Future<BulkVoidResult> execute({
    required List<String> ids,
    required String alasan,
    required bool Function() canContinue,
    void Function(int completed, int total)? onProgress,
  }) async {
    final uniqueIds = ids.toSet().toList();
    final reason = alasan.trim();
    if (reason.isEmpty || reason.runes.length > 255) {
      return BulkVoidResult(uniqueIds.map((id) => SetoranVoidOutcome(
          id,
          BulkVoidStatus.gagal,
          'Alasan pembatalan wajib diisi, maksimal 255 karakter.')));
    }
    final outcomes = <SetoranVoidOutcome>[];
    String? stopReason;
    var completed = 0;
    for (final id in uniqueIds) {
      if (stopReason != null || !canContinue()) {
        outcomes.add(SetoranVoidOutcome(id, BulkVoidStatus.belumDiproses,
            stopReason ?? 'Sesi berubah. Setoran ini belum diproses.'));
        continue;
      }
      try {
        final result = await _batalkan
            .execute(TransaksiBatalRequest(id: id, alasan: reason));
        outcomes.add(result.fold((failure) {
          final status = failure.response?.statusCode;
          if (status == null || status >= 500) {
            stopReason =
                'Proses dihentikan karena hasil permintaan sebelumnya belum dipastikan.';
            return SetoranVoidOutcome(id, BulkVoidStatus.belumDipastikan,
                'Status pembatalan belum dipastikan. Periksa riwayat terbaru sebelum mencoba lagi.');
          }
          if (status == 401 || status == 403) {
            stopReason =
                'Sesi atau izin akses tidak lagi berlaku. Setoran ini belum diproses.';
          }
          return SetoranVoidOutcome(
              id, BulkVoidStatus.gagal, failure.displayMessage);
        }, (detail) {
          if (!detail.isDibatalkan) {
            stopReason =
                'Proses dihentikan karena hasil permintaan sebelumnya belum dipastikan.';
            return SetoranVoidOutcome(id, BulkVoidStatus.belumDipastikan,
                'Status pembatalan belum dipastikan. Periksa riwayat terbaru sebelum mencoba lagi.');
          }
          return SetoranVoidOutcome(id, BulkVoidStatus.berhasil);
        }));
      } catch (_) {
        stopReason =
            'Proses dihentikan karena hasil permintaan sebelumnya belum dipastikan.';
        outcomes.add(SetoranVoidOutcome(id, BulkVoidStatus.belumDipastikan,
            'Status pembatalan belum dipastikan. Periksa riwayat terbaru sebelum mencoba lagi.'));
      }
      completed++;
      onProgress?.call(completed, uniqueIds.length);
    }
    return BulkVoidResult(outcomes);
  }
}
