import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';

/// The nasabah list was searched. Says whether anything was found and in which
/// tab (`aktif`, `tidak_aktif` or `menunggu`), never what was typed.
void nasabahSearched(
  AnalyticsClient client, {
  required bool? activeTab,
  required int resultCount,
}) =>
    client.capture('nasabah_dicari', {
      'ada_hasil': resultCount > 0,
      'filter': switch (activeTab) {
        true => 'aktif',
        false => 'tidak_aktif',
        null => 'menunggu',
      },
      'jumlah_hasil_kelas': switch (resultCount) {
        0 => '0',
        <= 5 => '1_5',
        <= 20 => '6_20',
        _ => 'lebih_20',
      },
    });

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

/// The names of the add-nasabah fields that were left wrong, from the values
/// typed (never the values themselves).
List<String> nasabahInvalidFields({
  required String nama,
  required String kode,
  required String email,
  required String noHp,
  required String alamat,
}) =>
    [
      if (nama.trim().isEmpty) 'nama',
      if (kode.trim().isEmpty) 'id_nasabah',
      if (email.trim().isEmpty) 'email',
      if (noHp.trim().isEmpty) 'no_hp',
      if (alamat.trim().runes.length < 10) 'alamat',
    ];

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

  /// The form was opened from [source] (`halaman_nasabah` or `dashboard`).
  void opened(String source) {
    _flowId = _newFlowId();
    _startedAt = _clock();
    _attempts = 0;
    _send('nasabah_tambah_dimulai', {'sumber': source});
  }

  /// The save button was pressed.
  void submitTapped() => _attempts++;

  /// The form was refused because of [fields].
  void rejected(List<String> fields) => _send('validasi_gagal', {
        'tugas': 'tambah_nasabah',
        'bidang': fields.isEmpty ? ['lainnya'] : fields,
        'jumlah_masalah': fields.isEmpty ? 1 : fields.length,
      });

  /// The nasabah was saved.
  void saved() => _send('nasabah_ditambah', {
        'durasi_detik': _clock().difference(_startedAt).inSeconds,
        'percobaan_ke': _attempts,
      });

  void _send(String event, Map<String, Object?> properties) =>
      _client.capture(event, {'alur_id': _flowId, ...properties});
}
