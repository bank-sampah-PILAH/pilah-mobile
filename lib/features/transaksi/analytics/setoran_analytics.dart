import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/setoran_draft.dart';

/// How far a pengurus got with a setoran when they left without saving.
enum SetoranStep {
  /// No nasabah chosen yet.
  nasabah('nasabah'),

  /// A nasabah, but the items are not ready to save.
  item('item'),

  /// Everything needed was filled in.
  siapSimpan('siap_simpan');

  const SetoranStep(this.name);

  final String name;
}

/// The events of one attempt at recording a setoran.
///
/// They say what the pengurus did and how long it took, never who the nasabah
/// is, what was weighed for them or what it was worth. Every event carries the
/// same `alur_id`, so a funnel counts attempts and not only people. Whether
/// anything is actually sent is up to the client, which ignores everything until
/// the pengurus has agreed.
class SetoranAnalytics {
  SetoranAnalytics(
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
  late DateTime _lastStepAt;
  int _attempts = 0;
  bool _saved = false;
  final _filledRows = <Object>{};

  static const _problemNames = {
    SetoranProblem.noNasabah: 'nasabah_belum_dipilih',
    SetoranProblem.noItems: 'belum_ada_item',
    SetoranProblem.itemWithoutJenis: 'item_tanpa_jenis',
    SetoranProblem.nonPositiveBerat: 'berat_nol',
  };

  /// The form was opened.
  void started() {
    _flowId = _newFlowId();
    _startedAt = _lastStepAt = _clock();
    _attempts = 0;
    _saved = false;
    _filledRows.clear();
    _send('setoran_dimulai');
  }

  /// A nasabah was chosen, and how long that took since the last step.
  void nasabahChosen() => _send('setoran_nasabah_dipilih', {
        'durasi_langkah_detik': _sinceLastStep(),
      });

  /// An item got a jenis and a weight for the first time. [row] tells the
  /// items apart and is never sent. Each item is counted once however often it
  /// is edited afterwards, and removing it does not take it back, so `item_ke`
  /// is the order in which the items of this flow were filled in.
  void itemFilled(Object row) {
    if (_flowId == null || !_filledRows.add(row)) return;
    _send('setoran_item_diisi', {'item_ke': _filledRows.length});
  }

  /// The save button was pressed, counting how many times it has been.
  void saveTapped({required int itemCount}) {
    _attempts++;
    _send('setoran_simpan_ditekan', {
      'jumlah_item': itemCount,
      'percobaan_ke': _attempts,
      'durasi_langkah_detik': _sinceLastStep(),
    });
  }

  /// The form was refused, with the fixed names of what was wrong.
  void validationFailed(Set<SetoranProblem> problems) {
    final names = [
      for (final problem in SetoranProblem.values)
        if (problems.contains(problem)) _problemNames[problem]!,
    ];
    _send('validasi_gagal', {
      'tugas': 'setoran',
      'masalah': names,
      'jumlah_masalah': names.length,
    });
  }

  /// The setoran was saved.
  void saved({
    required int itemCount,
    required int distinctJenis,
    required double totalKg,
  }) {
    _saved = true;
    _send('setoran_disimpan', {
      'jumlah_item': itemCount,
      'jumlah_jenis_berbeda': distinctJenis,
      'berat_total_kg': (totalKg * 10).round() / 10,
      'durasi_detik': _sinceStart(),
      'percobaan_ke': _attempts,
    });
  }

  /// What the pengurus did on the success panel.
  void afterSave({required bool opened, required bool templateUsed}) =>
      _send('setoran_aksi_sesudah_simpan', {
        'aksi': 'kirim_wa',
        'berhasil': opened,
        'template_wa_dipakai': templateUsed,
      });

  /// The pengurus finished from the success panel without sending the message.
  void finishedWithoutMessage() =>
      _send('setoran_aksi_sesudah_simpan', {'aksi': 'selesai'});

  /// The pengurus left the form without saving.
  void leftWithoutSaving(SetoranStep step) {
    if (_flowId == null || _saved) return;
    _send('setoran_dibatalkan', {
      'langkah_terakhir': step.name,
      'durasi_detik': _sinceStart(),
    });
  }

  int _sinceStart() => _clock().difference(_startedAt).inSeconds;

  int _sinceLastStep() {
    final now = _clock();
    final seconds = now.difference(_lastStepAt).inSeconds;
    _lastStepAt = now;
    return seconds;
  }

  void _send(String event, [Map<String, Object?> properties = const {}]) {
    final flowId = _flowId;
    if (flowId == null) return;
    _client.capture(event, {'alur_id': flowId, ...properties});
  }
}

/// The events of correcting a setoran that is already recorded (PIL-427).
///
/// They say that an edit was opened, what kind of thing was changed and whether
/// the server refused it. The reason the pengurus wrote, the note and the
/// weights stay in the app.
class SetoranEditAnalytics {
  SetoranEditAnalytics(
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

  /// The edit sheet was opened.
  void started() {
    _flowId = _newFlowId();
    _startedAt = _clock();
    _send('setoran_ubah_dimulai');
  }

  /// The correction was saved, naming what kind of thing changed.
  void saved({
    required int itemCount,
    required bool itemsChanged,
    required bool noteChanged,
  }) =>
      _send('setoran_diubah', {
        'jumlah_item': itemCount,
        'bidang_diubah': [
          if (itemsChanged) 'item',
          if (noteChanged) 'catatan',
        ],
        'durasi_detik': _sinceStart(),
      });

  int _sinceStart() => _clock().difference(_startedAt).inSeconds;

  void _send(String event, [Map<String, Object?> properties = const {}]) {
    final flowId = _flowId;
    if (flowId == null) return;
    _client.capture(event, {'alur_id': flowId, ...properties});
  }
}
