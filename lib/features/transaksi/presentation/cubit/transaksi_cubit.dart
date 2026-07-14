import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/resend_wa_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

@lazySingleton
class TransaksiCubit extends Cubit<TransaksiState> {
  final GetTransaksiUseCase getTransaksiUseCase;
  final GetTransaksiDetailUseCase getTransaksiDetailUseCase;
  final AddTransaksiUseCase addTransaksiUseCase;
  final ExportTransaksiUseCase exportTransaksiUseCase;
  final ResendWaUseCase resendWaUseCase;

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
    this.resendWaUseCase,
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

  /// Creates a setoran transaction and then automatically fires the WhatsApp
  /// notification for it. A failed WA send is reported via `waSuccess` but never
  /// rolls back the transaction. On success the list is reloaded *after* the WA
  /// attempt so the new item appears with its authoritative `status_wa`
  /// (terkirim/gagal) without a manual refresh; otherwise the creation
  /// [NetworkException] is returned so the page can show the error.
  Future<({TransaksiCreated? created, NetworkException? error, bool waSuccess})>
      addTransaksiWithWa(TransaksiRequest request) async {
    final result = await addTransaksiUseCase.execute(request);
    return result.fold(
      (failure) async => (created: null, error: failure, waSuccess: false),
      (created) async {
        // Chain the WA notification onto the freshly created transaction.
        final waResult = await resendWaUseCase.execute(created.id);
        // Reload only after the WA attempt so the list reflects the final
        // backend status_wa rather than the transient "belum dikirim".
        await loadTransaksi();
        return (created: created, error: null, waSuccess: waResult.isRight());
      },
    );
  }

  Future<TransaksiDetailEntity?> fetchTransaksiDetail(String id) async {
    final result = await getTransaksiDetailUseCase.execute(id);
    return result.fold((_) => null, (data) => data);
  }

  /// Resends the WhatsApp notification for transaction [id]. Returns whether it
  /// succeeded and, on failure, the user-facing error message so the caller can
  /// react on the button itself. On success the matching list item's WA status
  /// is flipped locally and the filtered list re-emitted, so the list reflects
  /// the change without triggering a full network reload.
  Future<({bool success, String? error})> resendWa(String id) async {
    final result = await resendWaUseCase.execute(id);
    return result.fold(
      (failure) => (success: false, error: failure.displayMessage),
      (status) {
        _applyWaStatus(id, isWaSuccess: status == 'sent');
        return (success: true, error: null);
      },
    );
  }

  /// Updates the cached [id] transaction's WA status in place and re-emits the
  /// filtered list. No-op (no emit) when the item isn't in the current cache.
  void _applyWaStatus(String id, {required bool isWaSuccess}) {
    var changed = false;
    final updated = _allTransaksi.map((group) {
      final transactions = group.transactions.map((t) {
        if (t.id == id && t.isWaSuccess != isWaSuccess) {
          changed = true;
          return t.copyWith(isWaSuccess: isWaSuccess);
        }
        return t;
      }).toList();
      return TransaksiGroupEntity(header: group.header, transactions: transactions);
    }).toList();
    if (!changed) return;
    _allTransaksi = updated;
    _emitFiltered();
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
