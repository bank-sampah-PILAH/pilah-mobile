import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/aktivitas_entity.dart';
import '../../domain/entities/transaksi_filter.dart';
import '../../domain/use_cases/export_transaksi_usecase.dart';
import '../../domain/use_cases/get_aktivitas_usecase.dart';
import 'riwayat_aktivitas_state.dart';

/// One server-paginated feed, scoped by period, type and search.
@lazySingleton
class RiwayatAktivitasCubit extends Cubit<RiwayatAktivitasState> {
  RiwayatAktivitasCubit(this._getAktivitas, this._export)
      : super(const RiwayatAktivitasState());
  final GetAktivitasUseCase _getAktivitas;
  final ExportTransaksiUseCase _export;
  int _generation = 0;
  int _page = 0;

  TransaksiFilter _filter(int page) => TransaksiFilter(
        periode: state.periode,
        dariTanggal: state.dariTanggal,
        sampaiTanggal: state.sampaiTanggal,
        tipe: state.tipeFilter.name,
        search: state.search,
        page: page,
      );

  Future<void> load({bool silent = false}) async {
    final generation = ++_generation;
    _page = 0;
    emit(state.copyWith(
        status: silent && state.items.isNotEmpty
            ? AktivitasStatus.loaded
            : AktivitasStatus.loading,
        hasNext: false,
        loadingMore: false));
    final result = await _getAktivitas.execute(_filter(1));
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => emit(state.copyWith(
          status: AktivitasStatus.failure,
          items: [],
          errorMessage: failure.displayMessage)),
      (page) {
        _page = 1;
        emit(state.copyWith(
            status: AktivitasStatus.loaded,
            items: page.items,
            hasNext: page.hasNext));
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
    emit(state.copyWith(loadingMore: true));
    final result = await _getAktivitas.execute(_filter(_page + 1));
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => emit(state.copyWith(
          loadingMore: false, errorMessage: failure.displayMessage)),
      (page) {
        _page++;
        final ids = state.items.map(_key).toSet();
        emit(state.copyWith(items: [
          ...state.items,
          ...page.items.where((item) => ids.add(_key(item)))
        ], hasNext: page.hasNext, loadingMore: false));
      },
    );
  }

  String _key(ActivitasEntity item) =>
      '${item.tipe.name}:${item.transaksi?.id ?? item.pencairan?.id}';

  void setPeriode(String periode) {
    if (state.periode == periode && state.dariTanggal == null) return;
    emit(RiwayatAktivitasState(
        periode: periode, tipeFilter: state.tipeFilter, search: state.search));
    load();
  }

  void applyCustomRange(DateTime start, DateTime end) {
    emit(RiwayatAktivitasState(
        periode: 'custom',
        dariTanggal: start,
        sampaiTanggal: end,
        tipeFilter: state.tipeFilter,
        search: state.search));
    load();
  }

  void setTipeFilter(AktivitasTipeFilter tipe) {
    if (state.tipeFilter == tipe) return;
    emit(state.copyWith(tipeFilter: tipe, items: []));
    load();
  }

  void search(String query) {
    if (state.search == query.trim()) return;
    emit(state.copyWith(search: query.trim(), items: []));
    load();
  }

  /// XLSX expansion to include payouts is owned by PIL-248.
  Future<({TransaksiExport? export, String? error})> exportTransaksi() async {
    final result = await _export.execute(_filter(1));
    return result.fold(
        (failure) => (export: null, error: failure.displayMessage),
        (data) => (export: data, error: null));
  }

  void reset() {
    _generation++;
    _page = 0;
    emit(const RiwayatAktivitasState());
  }
}
