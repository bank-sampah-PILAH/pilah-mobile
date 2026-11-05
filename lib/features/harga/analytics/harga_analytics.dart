import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';
import 'package:pilah_mobile/core/analytics/form_abandonment.dart';

/// The categories a jenis sampah can have, as the backend names them. Anything
/// else is sent as `dll`, so a value somebody typed can never reach analytics.
const _categories = {'kertas', 'plastik', 'logam', 'kaca', 'dll'};

/// One opening of the jenis sampah form. The panel outlives a single row, so a
/// save that is still running can end after the form moved to another row;
/// holding the opening it started lets its result land on the right one.
class HargaFormFlow {
  HargaFormFlow._(this._id, this._startedAt);

  final String _id;
  final DateTime _startedAt;
  int _attempts = 0;
  late final FormAbandonment _abandonment;
}

/// The events of filling in the jenis sampah form.
///
/// They say that the form was opened, how it ended, whether the price changed
/// and which category it is in. They never carry a price, a name or a code.
/// Every event of one opening carries one flow id. A form left without saving
/// is reported as cancelled, once.
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

  HargaFormFlow? _flow;

  /// The form was opened, to add a jenis or to change one. Opening it for
  /// another row means the form of the previous one was left.
  void opened({required bool editing}) {
    _flow?._abandonment.closed();
    final flow = HargaFormFlow._(_newFlowId(), _clock());
    flow._abandonment = FormAbandonment(
      () => _send(flow, 'harga_dibatalkan', {
        'durasi_detik': _clock().difference(flow._startedAt).inSeconds,
        'percobaan_ke': flow._attempts,
      }),
    )..opened();
    _flow = flow;
    _send(flow, 'harga_form_dibuka', {'mode': _mode(editing)});
  }

  /// The save button was pressed.
  void submitTapped() => _flow?._attempts++;

  /// The form passed its checks and the request to save went out. The result is
  /// reported with the returned [HargaFormFlow].
  HargaFormFlow? sending() {
    final flow = _flow;
    flow?._abandonment.sending();
    return flow;
  }

  /// The save of [flow] was refused.
  void sendFailed(HargaFormFlow? flow) => flow?._abandonment.sendFailed();

  /// What the form was opened for was done without a save of the fields (the
  /// status of the jenis was changed), so closing it is not a cancellation.
  void finished(HargaFormFlow? flow) => flow?._abandonment.saved();

  /// The form was closed. Leaving without a save is a cancelled form, reported
  /// once; a save still on its way decides it when it ends.
  void closed() => _flow?._abandonment.closed();

  /// The jenis was saved. This is sent even if the panel has moved on to
  /// another row meanwhile, because the change did happen; [flow] is the
  /// opening the save was started from.
  void saved({
    HargaFormFlow? flow,
    required bool editing,
    required bool priceChanged,
    required String category,
  }) {
    final saved = flow ?? _flow;
    if (saved == null) return;
    saved._abandonment.saved();
    _send(saved, 'harga_disimpan', {
      'mode': _mode(editing),
      'harga_berubah': priceChanged,
      'kategori': _categories.contains(category) ? category : 'dll',
      'percobaan_ke': saved._attempts,
      'durasi_detik': _clock().difference(saved._startedAt).inSeconds,
    });
  }

  String _mode(bool editing) => editing ? 'ubah' : 'baru';

  void _send(
      HargaFormFlow flow, String event, Map<String, Object?> properties) {
    _client.capture(event, {'alur_id': flow._id, ...properties});
  }
}

/// A jenis sampah was activated or deactivated. Which one is never sent.
void hargaStatusChanged(AnalyticsClient client, {required bool activated}) =>
    client.capture('harga_status_diubah',
        {'aksi': activated ? 'aktifkan' : 'nonaktifkan'});

/// The price history of a jenis sampah was opened.
void hargaHistoryOpened(AnalyticsClient client) =>
    client.capture('harga_riwayat_dibuka');
