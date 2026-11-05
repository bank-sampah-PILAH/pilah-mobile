import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';
import 'package:pilah_mobile/core/analytics/form_abandonment.dart';

/// A pending nasabah was approved or rejected. [sinceOpened] is how long the
/// decision took from opening the question.
void nasabahDecided(
  AnalyticsClient client, {
  required bool approved,
  required Duration sinceOpened,
}) =>
    client.capture('nasabah_pengajuan_diproses', {
      'keputusan': approved ? 'setuju' : 'tolak',
      'durasi_sejak_dibuka_detik': sinceOpened.inSeconds,
    });

/// The events of adding a nasabah, all with one flow id.
class NasabahAddAnalytics {
  NasabahAddAnalytics(
    this._client, {
    DateTime Function() clock = DateTime.now,
    String Function() newFlowId = newFlowId,
  })  : _clock = clock,
        _newFlowId = newFlowId;

  final AnalyticsClient _client;
  final DateTime Function() _clock;
  final String Function() _newFlowId;

  late String _flowId;
  late DateTime _startedAt;
  int _attempts = 0;
  late final _abandonment = FormAbandonment(
    () => _send('nasabah_tambah_dibatalkan', {
      'durasi_detik': _clock().difference(_startedAt).inSeconds,
      'percobaan_ke': _attempts,
    }),
  );

  /// The form was opened from [source] (`halaman_nasabah` or `dashboard`).
  void opened(String source) {
    _flowId = _newFlowId();
    _startedAt = _clock();
    _attempts = 0;
    _abandonment.opened();
    _send('nasabah_tambah_dimulai', {'sumber': source});
  }

  /// The save button was pressed.
  void submitTapped() => _attempts++;

  /// The form passed its checks and the request to save went out.
  void sending() => _abandonment.sending();

  /// The server refused the save.
  void sendFailed() => _abandonment.sendFailed();

  /// The form was closed. Leaving without a save is a cancelled form, reported
  /// once; a save still on its way decides it when it ends.
  void closed() => _abandonment.closed();

  /// The form was refused because of [fields].
  void rejected(List<String> fields) => _send('validasi_gagal', {
        'tugas': 'tambah_nasabah',
        'bidang': fields.isEmpty ? ['lainnya'] : fields,
        'jumlah_masalah': fields.isEmpty ? 1 : fields.length,
      });

  /// The nasabah was saved.
  void saved() {
    _abandonment.saved();
    _send('nasabah_ditambah', {
      'durasi_detik': _clock().difference(_startedAt).inSeconds,
      'percobaan_ke': _attempts,
    });
  }

  void _send(String event, Map<String, Object?> properties) =>
      _client.capture(event, {'alur_id': _flowId, ...properties});
}
