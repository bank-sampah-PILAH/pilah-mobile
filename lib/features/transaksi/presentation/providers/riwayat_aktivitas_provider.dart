import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/search_analytics.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/transaksi/analytics/riwayat_analytics.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../domain/entities/aktivitas_entity.dart';
import '../../domain/entities/transaksi_filter.dart';
import '../../domain/use_cases/export_transaksi_usecase.dart';
import '../../domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';

/// One server-paginated feed, scoped by period, type and search.
final riwayatAktivitasProvider =
    NotifierProvider<RiwayatAktivitasNotifier, RiwayatAktivitasState>(
  () => RiwayatAktivitasNotifier(
    di<GetAktivitasUseCase>(),
    di<ExportTransaksiUseCase>(),
  ),
);

class RiwayatAktivitasNotifier extends Notifier<RiwayatAktivitasState> {
  RiwayatAktivitasNotifier(this._getAktivitas, this._export);

  @override
  RiwayatAktivitasState build() {
    ref.onDispose(_search.closed);
    return const RiwayatAktivitasState();
  }

  late final SearchAnalytics _search =
      SearchAnalytics(ref.read(analyticsClientProvider), area: 'riwayat');
  final GetAktivitasUseCase _getAktivitas;
  final ExportTransaksiUseCase _export;
  int _generation = 0;
  int _page = 0;
  int? _pageSize;

  TransaksiFilter _filter(int page) => TransaksiFilter(
        periode: state.periode,
        dariTanggal: state.dariTanggal,
        sampaiTanggal: state.sampaiTanggal,
        tipe: state.tipeFilter.name,
        search: state.search,
        page: page,
        pageSize: _pageSize,
      );

  Future<void> load({bool silent = false, int? pageSize}) async {
    _pageSize = pageSize ?? _pageSize;
    final generation = ++_generation;
    _page = 0;
    state = state.copyWith(
        status: silent && state.items.isNotEmpty
            ? AktivitasStatus.loaded
            : AktivitasStatus.loading,
        hasNext: false,
        currentPage: 1,
        pageSize: _pageSize ?? 20,
        totalCount: silent ? state.totalCount : 0,
        clearSummary: true,
        clearRetryPage: true,
        loadingMore: false);
    final result = await _getAktivitas.execute(_filter(1));
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = state.copyWith(
          status: AktivitasStatus.failure,
          items: [],
          totalCount: 0,
          clearSummary: true,
          errorMessage: failure.displayMessage),
      (page) {
        _page = 1;
        state = state.copyWith(
            status: AktivitasStatus.loaded,
            items: page.items,
            summary: page.summary,
            currentPage: 1,
            pageSize: _pageSize ?? 20,
            totalCount: page.totalCount,
            hasNext: page.hasNext);
        _search.resultsSettled(query: state.search, count: page.totalCount);
      },
    );
  }

  Future<void> loadPage(int page) async {
    final pageCount = (state.totalCount + state.pageSize - 1) ~/ state.pageSize;
    if (page < 1 ||
        page > pageCount ||
        page == _page ||
        state.loadingMore ||
        state.status != AktivitasStatus.loaded) {
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(loadingMore: true, clearRetryPage: true);
    final result = await _getAktivitas.execute(_filter(page));
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = state.copyWith(
          loadingMore: false,
          retryPage: page,
          errorMessage: failure.displayMessage),
      (data) {
        _page = page;
        state = state.copyWith(
            status: AktivitasStatus.loaded,
            items: data.items,
            summary: data.summary,
            currentPage: page,
            totalCount: data.totalCount,
            hasNext: data.hasNext,
            loadingMore: false,
            clearRetryPage: true);
      },
    );
  }

  Future<void> loadMore() async {
    if (!state.hasNext ||
        state.loadingMore ||
        state.status != AktivitasStatus.loaded) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(loadingMore: true);
    final result = await _getAktivitas.execute(_filter(_page + 1));
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = state.copyWith(
          loadingMore: false,
          clearRetryPage: true,
          errorMessage: failure.displayMessage),
      (page) {
        _page++;
        final ids = state.items.map(_key).whereType<String>().toSet();
        state = state.copyWith(
            items: [
              ...state.items,
              ...page.items.where((item) {
                final key = _key(item);
                return key == null || ids.add(key);
              })
            ],
            hasNext: page.hasNext,
            currentPage: _page,
            totalCount: page.totalCount,
            loadingMore: false,
            clearRetryPage: true);
      },
    );
  }

  String? _key(ActivitasEntity item) {
    final id = item.transaksi?.id ?? item.pencairan?.id;
    if (id == null || id.isEmpty) return null;
    return '${item.tipe.name}:$id';
  }

  void _filterChanged(RiwayatFilterKind kind, {String? value}) =>
      riwayatFilterChanged(ref.read(analyticsClientProvider), kind,
          value: value);

  void setPeriode(String periode) {
    if (state.periode == periode && state.dariTanggal == null) return;
    state = RiwayatAktivitasState(
        periode: periode, tipeFilter: state.tipeFilter, search: state.search);
    _filterChanged(RiwayatFilterKind.periode, value: periode);
    load();
  }

  void applyCustomRange(DateTime start, DateTime end) {
    state = RiwayatAktivitasState(
        periode: 'custom',
        dariTanggal: start,
        sampaiTanggal: end,
        tipeFilter: state.tipeFilter,
        search: state.search);
    _filterChanged(RiwayatFilterKind.periode, value: 'kustom');
    load();
  }

  void setTipeFilter(AktivitasTipeFilter tipe) {
    if (state.tipeFilter == tipe) return;
    state = state.copyWith(tipeFilter: tipe, items: []);
    _filterChanged(RiwayatFilterKind.tipe, value: tipe.name);
    load();
  }

  void search(String query) {
    if (state.search == query.trim()) return;
    state = state.copyWith(search: query.trim(), items: []);
    _search.queryChanged(state.search);
    load();
  }

  /// A row of the report was opened. When the report is showing a search, that
  /// is the row it led to, and its position in the results is reported.
  void rowOpened(ActivitasEntity item) {
    final key = _key(item);
    final index = state.items.indexWhere((other) => _key(other) == key);
    if (index >= 0) _search.picked(position: index + 1);
  }

  /// The pengurus left the report while it was showing a search. The report
  /// itself stays alive in the shell, so only this ends the search, and the
  /// next words typed start a new one.
  void searchLeft() => _search.closed();

  /// Kembali ke periode, tipe, dan pencarian bawaan, lalu memuat ulang.
  void resetFilters() {
    state = const RiwayatAktivitasState();
    _search.queryChanged('');
    _filterChanged(RiwayatFilterKind.reset);
    load();
  }

  /// Export the same period, type and search as the displayed report.
  Future<({TransaksiExport? export, String? error})> exportTransaksi() async {
    final result = await _export.execute(_filter(1));
    return result.fold(
        (failure) => (export: null, error: failure.displayMessage),
        (data) => (export: data, error: null));
  }

  void reset() {
    _search.closed();
    _generation++;
    _page = 0;
    _pageSize = null;
    state = const RiwayatAktivitasState();
  }
}
