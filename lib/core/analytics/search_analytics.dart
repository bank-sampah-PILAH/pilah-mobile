import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';

/// The events of searching a list, from the first words typed to the row that
/// was chosen or the search that was given up.
///
/// One search is one session with one `alur_id`. It says how many results each
/// try found, how many tries it took, where the chosen row was in the list and
/// how long it all took. The words typed never leave the app, and neither does
/// their exact length, only a class of it. One class serves every list that can
/// be searched, so they can be compared.
class SearchAnalytics {
  SearchAnalytics(
    this._client, {
    required this.area,
    DateTime Function() clock = DateTime.now,
    String Function() newFlowId = newFlowId,
  })  : _clock = clock,
        _newFlowId = newFlowId;

  /// Which list is searched, by a fixed name (`nasabah`, `riwayat`, `harga`,
  /// `pemilih_nasabah`).
  final String area;

  final AnalyticsClient _client;
  final DateTime Function() _clock;
  final String Function() _newFlowId;

  /// A query shorter than this is not a search.
  static const minLength = 2;

  String? _flowId;
  late DateTime _startedAt;
  int _attempts = 0;
  String? _lastQuery;
  String? _lastFilter;
  int? _lastCount;

  /// The words of the search that ended with a row picked. The list showing
  /// them again (a reload after the pick, coming back to the page) is not a new
  /// search: only other words, clearing them or leaving the list start one.
  String? _pickedQuery;

  /// The text of the search field changed to [query].
  void queryChanged(String query) {
    final text = query.trim();
    if (text.length < minLength) {
      _pickedQuery = null;
      _giveUp();
      return;
    }
    if (_isPicked(text)) return;
    _begin();
  }

  /// The results for [query] are in, [count] of them, in the tab [filter] when
  /// the list has tabs. A query that is the same as the last one settled, in
  /// the same tab, is not reported again.
  void resultsSettled({
    required String query,
    required int count,
    String? filter,
  }) {
    final text = query.trim();
    if (text.length < minLength || _isPicked(text)) return;
    _begin();
    if (text == _lastQuery && filter == _lastFilter) return;
    _lastQuery = text;
    _lastFilter = filter;
    _lastCount = count;
    _attempts++;
    _send('pencarian_hasil', {
      'jumlah_hasil_kelas': _countClass(count),
      'panjang_kueri_kelas': _lengthClass(text.length),
      'percobaan_ke': _attempts,
      'filter': filter,
    });
  }

  /// A row of the results was chosen, [position] counting from 1.
  void picked({required int position}) {
    if (_flowId == null) return;
    _send('pencarian_dipilih', {
      'posisi_hasil_kelas': switch (position) {
        <= 1 => '1',
        <= 3 => '2_3',
        <= 10 => '4_10',
        _ => 'lebih_10',
      },
      'percobaan_ke': _attempts,
      'durasi_detik': _clock().difference(_startedAt).inSeconds,
    });
    _pickedQuery = _lastQuery;
    _end();
  }

  /// The list was left. A search that showed results and chose nothing was given
  /// up.
  void closed() {
    _pickedQuery = null;
    _giveUp();
  }

  /// Whether [text] is the search that already ended with a row picked. Other
  /// words end that: they are a new search.
  bool _isPicked(String text) {
    if (_pickedQuery == null) return false;
    if (text == _pickedQuery) return true;
    _pickedQuery = null;
    return false;
  }

  void _begin() {
    if (_flowId != null) return;
    _flowId = _newFlowId();
    _startedAt = _clock();
    _attempts = 0;
    _lastQuery = null;
    _lastFilter = null;
    _lastCount = null;
    _send('pencarian_dimulai');
  }

  void _giveUp() {
    if (_flowId == null) return;
    if (_attempts > 0) {
      _send('pencarian_ditinggalkan', {
        'percobaan_ke': _attempts,
        'hasil_terakhir_kelas': _countClass(_lastCount ?? 0),
        'durasi_detik': _clock().difference(_startedAt).inSeconds,
      });
    }
    _end();
  }

  void _end() => _flowId = null;

  static String _countClass(int count) => switch (count) {
        <= 0 => '0',
        <= 5 => '1_5',
        <= 20 => '6_20',
        _ => 'lebih_20',
      };

  static String _lengthClass(int length) => switch (length) {
        <= 2 => '2',
        <= 5 => '3_5',
        _ => 'lebih_5',
      };

  void _send(String event, [Map<String, Object?> properties = const {}]) {
    final flowId = _flowId;
    if (flowId == null) return;
    _client.capture(event, {'alur_id': flowId, 'area': area, ...properties});
  }
}
