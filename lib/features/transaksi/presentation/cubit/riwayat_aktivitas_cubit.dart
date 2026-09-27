import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';

import 'riwayat_aktivitas_state.dart';

/// Backs the unified Riwayat Aktivitas screen (PIL-282): setoran and
/// pencairan merged into one chronological feed for the same period, with a
/// client-side type filter and search. Kept separate from [TransaksiCubit],
/// which still owns creating a setoran and the transaction detail sheet.
@lazySingleton
class RiwayatAktivitasCubit extends Cubit<RiwayatAktivitasState> {
  final GetTransaksiUseCase _getTransaksiUseCase;
  final PencairanUseCases _pencairanUseCases;
  final ExportTransaksiUseCase _exportTransaksiUseCase;

  List<ActivitasEntity> _all = [];
  String _periode = 'bulan_ini';
  DateTime? _dariTanggal;
  DateTime? _sampaiTanggal;
  AktivitasTipeFilter _tipeFilter = AktivitasTipeFilter.semua;
  String _search = '';

  RiwayatAktivitasCubit(
    this._getTransaksiUseCase,
    this._pencairanUseCases,
    this._exportTransaksiUseCase,
  ) : super(const RiwayatAktivitasState());

  TransaksiFilter _transaksiFilter() => TransaksiFilter(
        periode: _periode,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
      );

  /// The matching pencairan period, or null when the current periode has no
  /// pencairan equivalent (a custom setoran date range).
  RiwayatPeriode? _riwayatPeriode() {
    switch (_periode) {
      case 'bulan_ini':
        return RiwayatPeriode.bulanIni;
      case 'bulan_lalu':
        return RiwayatPeriode.bulanLalu;
      default:
        return null;
    }
  }

  /// Fetches both feeds for the current periode and merges them.
  ///
  /// Pass [silent] to skip the loading emit — pull-to-refresh already shows a
  /// spinner, so the list should stay on screen rather than collapse under it.
  Future<void> load({bool silent = false}) async {
    if (!silent || state.status != AktivitasStatus.loaded) {
      emit(state.copyWith(status: AktivitasStatus.loading));
    }

    final transaksiResult = await _getTransaksiUseCase.execute(_transaksiFilter());
    await transaksiResult.fold(
      (failure) async {
        if (isClosed) return;
        emit(RiwayatAktivitasState(
          status: AktivitasStatus.failure,
          periode: _periode,
          dariTanggal: _dariTanggal,
          sampaiTanggal: _sampaiTanggal,
          tipeFilter: _tipeFilter,
          search: _search,
          errorMessage: failure.displayMessage,
        ));
      },
      (groups) async {
        final riwayatPeriode = _riwayatPeriode();
        final pencairanResult = riwayatPeriode == null
            ? null
            : await _pencairanUseCases
                .getRiwayat(RiwayatPencairanFilter(periode: riwayatPeriode));
        if (isClosed) return;

        final setoranItems = [
          for (final group in groups)
            for (final t in group.transactions) ActivitasEntity.fromTransaksi(t),
        ];
        final pencairanItems = pencairanResult?.fold(
              // A failed pencairan fetch degrades to "setoran only" rather
              // than hiding a feed that did load.
              (_) => const <ActivitasEntity>[],
              (items) => items.map(ActivitasEntity.fromPencairan).toList(),
            ) ??
            const <ActivitasEntity>[];

        _all = [...setoranItems, ...pencairanItems]
          ..sort((a, b) {
            final da = a.tanggal;
            final db = b.tanggal;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        _emitFiltered();
      },
    );
  }

  void setPeriode(String periode) {
    if (_periode == periode && _dariTanggal == null && _sampaiTanggal == null) {
      return;
    }
    _periode = periode;
    _dariTanggal = null;
    _sampaiTanggal = null;
    load();
  }

  void applyCustomRange(DateTime start, DateTime end) {
    _periode = 'custom';
    _dariTanggal = start;
    _sampaiTanggal = end;
    load();
  }

  void setTipeFilter(AktivitasTipeFilter tipe) {
    _tipeFilter = tipe;
    _emitFiltered();
  }

  void search(String query) {
    _search = query;
    _emitFiltered();
  }

  /// Downloads the setoran-only XLSX export for the current period. Returns
  /// the file bytes on success, otherwise a user-facing error message.
  Future<({TransaksiExport? export, String? error})> exportTransaksi() async {
    final result = await _exportTransaksiUseCase.execute(_transaksiFilter());
    return result.fold(
      (failure) => (export: null, error: failure.displayMessage),
      (data) => (export: data, error: null),
    );
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _all = [];
    _periode = 'bulan_ini';
    _dariTanggal = null;
    _sampaiTanggal = null;
    _tipeFilter = AktivitasTipeFilter.semua;
    _search = '';
    emit(const RiwayatAktivitasState());
  }

  void _emitFiltered() {
    final query = _search.trim().toLowerCase();
    final filtered = _all.where((item) {
      final matchesTipe = switch (_tipeFilter) {
        AktivitasTipeFilter.semua => true,
        AktivitasTipeFilter.setoran => item.tipe == ActivitasTipe.setoran,
        AktivitasTipeFilter.pencairan => item.tipe == ActivitasTipe.pencairan,
      };
      if (!matchesTipe) return false;
      if (query.isEmpty) return true;
      return item.searchTerm.toLowerCase().contains(query);
    }).toList();

    emit(RiwayatAktivitasState(
      status: AktivitasStatus.loaded,
      items: filtered,
      periode: _periode,
      dariTanggal: _dariTanggal,
      sampaiTanggal: _sampaiTanggal,
      tipeFilter: _tipeFilter,
      search: _search,
    ));
  }
}
