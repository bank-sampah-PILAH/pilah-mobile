import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

@lazySingleton
class TransaksiCubit extends Cubit<TransaksiState> {
  final GetTransaksiUseCase getTransaksiUseCase;
  final GetTransaksiDetailUseCase getTransaksiDetailUseCase;
  final AddTransaksiUseCase addTransaksiUseCase;
  final ExportTransaksiUseCase exportTransaksiUseCase;

  List<TransaksiGroupEntity> _allTransaksi = [];
  String _periode = 'bulan_ini';
  DateTime? _dariTanggal;
  DateTime? _sampaiTanggal;
  String _searchQuery = '';

  TransaksiCubit(
    this.getTransaksiUseCase,
    this.getTransaksiDetailUseCase,
    this.addTransaksiUseCase,
    this.exportTransaksiUseCase,
  ) : super(TransaksiInitial());

  String get periode => _periode;
  String get searchQuery => _searchQuery;

  TransaksiFilter _currentFilter() => TransaksiFilter(
        periode: _periode,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
      );

  Future<void> loadTransaksi() async {
    emit(TransaksiLoading());
    final result = await getTransaksiUseCase.execute(_currentFilter());
    result.fold(
      (failure) => emit(TransaksiError(failure.displayMessage)),
      (data) {
        _allTransaksi = data;
        _emitFiltered();
      },
    );
  }

  /// Switches to a named period (`bulan_ini`, `bulan_lalu`, …) and refetches
  /// from the backend with the matching `periode` query param.
  void setPeriode(String periode) {
    if (_periode == periode && _dariTanggal == null && _sampaiTanggal == null) {
      return;
    }
    _periode = periode;
    _dariTanggal = null;
    _sampaiTanggal = null;
    loadTransaksi();
  }

  /// Applies a custom date range (`periode=custom` with `dari_tanggal` /
  /// `sampai_tanggal`) and refetches from the backend.
  void applyCustomRange(DateTime start, DateTime end) {
    _periode = 'custom';
    _dariTanggal = start;
    _sampaiTanggal = end;
    loadTransaksi();
  }

  void searchTransaksi(String query) {
    _searchQuery = query;
    _emitFiltered();
  }

  /// Creates a setoran transaction. On success the list is reloaded and the
  /// backend-authoritative [TransaksiCreated] is returned; otherwise the
  /// [NetworkException] is returned so the page can show the error.
  Future<({TransaksiCreated? created, NetworkException? error})> addTransaksi(
    TransaksiRequest request,
  ) async {
    final result = await addTransaksiUseCase.execute(request);
    return result.fold(
      (failure) => (created: null, error: failure),
      (created) {
        loadTransaksi();
        return (created: created, error: null);
      },
    );
  }

  Future<TransaksiDetailEntity?> fetchTransaksiDetail(String id) async {
    final result = await getTransaksiDetailUseCase.execute(id);
    return result.fold((_) => null, (data) => data);
  }

  /// Downloads the XLSX export for the current filter. Returns the file bytes
  /// on success, otherwise a user-facing error message.
  Future<({TransaksiExport? export, String? error})> exportTransaksi() async {
    final result = await exportTransaksiUseCase.execute(_currentFilter());
    return result.fold(
      (failure) => (export: null, error: failure.displayMessage),
      (data) => (export: data, error: null),
    );
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _allTransaksi = [];
    _periode = 'bulan_ini';
    _dariTanggal = null;
    _sampaiTanggal = null;
    _searchQuery = '';
    emit(TransaksiInitial());
  }

  /// Period filtering is applied server-side; here we only narrow the already
  /// fetched (period-scoped) results by the client-side search query.
  void _emitFiltered() {
    final query = _searchQuery.toLowerCase();
    final filteredGroups = <TransaksiGroupEntity>[];

    for (final group in _allTransaksi) {
      final filteredTransactions = group.transactions.where((t) {
        if (query.isEmpty) return true;
        return t.name.toLowerCase().contains(query) ||
            t.initials.toLowerCase().contains(query) ||
            t.subtitle.toLowerCase().contains(query);
      }).toList();

      if (filteredTransactions.isNotEmpty) {
        filteredGroups.add(TransaksiGroupEntity(
          header: group.header,
          transactions: filteredTransactions,
        ));
      }
    }

    emit(TransaksiLoaded(
      transaksiList: filteredGroups,
      periode: _periode,
      dariTanggal: _dariTanggal,
      sampaiTanggal: _sampaiTanggal,
      searchQuery: _searchQuery,
    ));
  }
}
