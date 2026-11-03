import 'package:pilah_mobile/core/client/network_exception.dart';
import '../entities/bulk_void_result.dart';
import '../entities/transaksi_entity.dart';
import 'batalkan_transaksi_usecase.dart';

typedef _VoidStep = ({SetoranVoidOutcome outcome, String? stopReason});

/// Compose PIL-428's existing operation. Each call owns its server transaction;
/// a refusal does not roll back earlier successes or duplicate saldo logic here.
class BatalkanBeberapaTransaksiUseCase {
  const BatalkanBeberapaTransaksiUseCase(this._batalkan);
  final BatalkanTransaksiUseCase _batalkan;
  static const _uncertainStop =
      'Proses dihentikan karena hasil permintaan sebelumnya belum dipastikan.';
  static const _uncertainMessage =
      'Status pembatalan belum dipastikan. Periksa riwayat terbaru sebelum mencoba lagi.';

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
      final step = await _voidOne(id, reason);
      outcomes.add(step.outcome);
      stopReason = step.stopReason;
      completed++;
      onProgress?.call(completed, uniqueIds.length);
    }
    return BulkVoidResult(outcomes);
  }

  Future<_VoidStep> _voidOne(String id, String reason) async {
    try {
      final result = await _batalkan
          .execute(TransaksiBatalRequest(id: id, alasan: reason));
      return result.fold(
        (failure) => _failure(id, failure),
        (detail) => detail.isDibatalkan
            ? (
                outcome: SetoranVoidOutcome(id, BulkVoidStatus.berhasil),
                stopReason: null
              )
            : _uncertain(id),
      );
    } catch (_) {
      // A lost/malformed response is not proof the server rolled back the write.
      return _uncertain(id);
    }
  }

  _VoidStep _failure(String id, NetworkException failure) {
    final status = failure.response?.statusCode;
    if (status == null || status >= 500) return _uncertain(id);
    return (
      outcome:
          SetoranVoidOutcome(id, BulkVoidStatus.gagal, failure.displayMessage),
      stopReason: status == 401 || status == 403
          ? 'Sesi atau izin akses tidak lagi berlaku. Setoran ini belum diproses.'
          : null,
    );
  }

  _VoidStep _uncertain(String id) => (
        outcome: SetoranVoidOutcome(
            id, BulkVoidStatus.belumDipastikan, _uncertainMessage),
        stopReason: _uncertainStop,
      );
}
