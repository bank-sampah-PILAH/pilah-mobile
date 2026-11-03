import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';

/// Why the schedule form was refused, as a fixed name.
enum JadwalProblem {
  /// A new schedule must start in the future.
  startInPast('waktu_mulai_lampau'),

  /// It must end after it starts.
  endBeforeStart('waktu_selesai_sebelum_mulai'),

  /// A field that is required was left empty.
  requiredFieldEmpty('bidang_wajib_kosong');

  const JadwalProblem(this.name);

  final String name;
}

/// The events of filling in the schedule form.
///
/// They say that the form was opened, how it ended and what kind of schedule it
/// was (its kind, whether it is for everyone, how far ahead and how long),
/// never where it is or what the notes say. Every event carries one flow id.
class JadwalFormAnalytics {
  JadwalFormAnalytics(
    this._client, {
    DateTime Function() clock = DateTime.now,
    String Function() newFlowId = newFlowId,
  })  : _clock = clock,
        _newFlowId = newFlowId;

  final AnalyticsClient _client;
  final DateTime Function() _clock;
  final String Function() _newFlowId;

  String? _flowId;
  late DateTime _startedAt;
  int _attempts = 0;

  /// The form was opened, to make a schedule or to change one.
  void opened({required bool editing}) {
    _flowId = _newFlowId();
    _startedAt = _clock();
    _attempts = 0;
    _send('jadwal_form_dibuka', {'mode': editing ? 'ubah' : 'baru'});
  }

  /// The save button was pressed.
  void submitTapped() => _attempts++;

  /// The form was refused.
  void rejected(JadwalProblem problem) => _send('validasi_gagal', {
        'tugas': 'jadwal',
        'masalah': [problem.name],
        'jumlah_masalah': 1,
      });

  /// The schedule was saved.
  void saved({
    required bool editing,
    required String activity,
    required String audience,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      _send(editing ? 'jadwal_diubah' : 'jadwal_dibuat', {
        'jenis': activity,
        'cakupan': audience == 'semua_nasabah' ? 'semua' : 'terpilih',
        'durasi_detik': _clock().difference(_startedAt).inSeconds,
        'percobaan_ke': _attempts,
        'jeda_hari_kelas': _daysAhead(startsAt),
        'lama_kegiatan_kelas': _length(endsAt.difference(startsAt)),
      });

  String _daysAhead(DateTime startsAt) {
    final now = _clock();
    final days = DateTime(startsAt.year, startsAt.month, startsAt.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return 'hari_ini';
    return days <= 7 ? '1_7_hari' : 'lebih_7_hari';
  }

  String _length(Duration length) {
    if (length < const Duration(hours: 1)) return 'kurang_1_jam';
    return length <= const Duration(hours: 3) ? '1_3_jam' : 'lebih_3_jam';
  }

  void _send(String event, Map<String, Object?> properties) {
    final flowId = _flowId;
    if (flowId == null) return;
    _client.capture(event, {'alur_id': flowId, ...properties});
  }
}

/// A schedule was published, cancelled or finished. [action] is the action's
/// name for the API (`terbitkan`, `batalkan`, `selesaikan`), and [statusBefore]
/// the status the schedule had.
void jadwalStatusChanged(
  AnalyticsClient client, {
  required String action,
  required String statusBefore,
}) =>
    client.capture('jadwal_status_diubah', {
      'aksi': action,
      'status_sebelumnya': statusBefore,
    });
