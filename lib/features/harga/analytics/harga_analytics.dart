import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';

/// The categories a jenis sampah can have, as the backend names them. Anything
/// else is sent as `dll`, so a value somebody typed can never reach analytics.
const _categories = {'kertas', 'plastik', 'logam', 'kaca', 'dll'};

/// The events of filling in the jenis sampah form.
///
/// They say that the form was opened, how it ended, whether the price changed
/// and which category it is in. They never carry a price, a name or a code.
/// Every event of one opening carries one flow id.
class HargaFormAnalytics {
  HargaFormAnalytics(
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

  /// The form was opened, to add a jenis or to change one.
  void opened({required bool editing}) {
    _flowId = _newFlowId();
    _startedAt = _clock();
    _attempts = 0;
    _send('harga_form_dibuka', {'mode': _mode(editing)});
  }

  /// The save button was pressed.
  void submitTapped() => _attempts++;

  /// The jenis was saved. This is sent even if the panel has moved on to
  /// another row meanwhile, because the change did happen.
  void saved({
    required bool editing,
    required bool priceChanged,
    required String category,
  }) {
    if (_flowId == null) return;
    _send('harga_disimpan', {
      'mode': _mode(editing),
      'harga_berubah': priceChanged,
      'kategori': _categories.contains(category) ? category : 'dll',
      'percobaan_ke': _attempts,
      'durasi_detik': _clock().difference(_startedAt).inSeconds,
    });
  }

  String _mode(bool editing) => editing ? 'ubah' : 'baru';

  void _send(String event, Map<String, Object?> properties) {
    final flowId = _flowId;
    if (flowId == null) return;
    _client.capture(event, {'alur_id': flowId, ...properties});
  }
}

/// A jenis sampah was activated or deactivated. Which one is never sent.
void hargaStatusChanged(AnalyticsClient client, {required bool activated}) =>
    client.capture('harga_status_diubah',
        {'aksi': activated ? 'aktifkan' : 'nonaktifkan'});

/// The price history of a jenis sampah was opened.
void hargaHistoryOpened(AnalyticsClient client) =>
    client.capture('harga_riwayat_dibuka');

/// The list was searched. Says whether anything was found, never what was
/// typed.
void hargaSearched(AnalyticsClient client, {required int resultCount}) =>
    client.capture('harga_dicari', {
      'ada_hasil': resultCount > 0,
      'jumlah_hasil_kelas': switch (resultCount) {
        0 => '0',
        <= 5 => '1_5',
        <= 20 => '6_20',
        _ => 'lebih_20',
      },
    });
