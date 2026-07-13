import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

@lazySingleton
class TransaksiCubit extends Cubit<TransaksiState> {
  final GetTransaksiUseCase getTransaksiUseCase;
  final GetTransaksiDetailUseCase getTransaksiDetailUseCase;
  final AddTransaksiUseCase addTransaksiUseCase;

  List<TransaksiGroupEntity> _allTransaksi = [];
  String _activeFilter = 'Semua Waktu';
  String _searchQuery = '';

  TransaksiCubit(
    this.getTransaksiUseCase,
    this.getTransaksiDetailUseCase,
    this.addTransaksiUseCase,
  ) : super(TransaksiInitial());

  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  Future<void> loadTransaksi() async {
    emit(TransaksiLoading());
    final result = await getTransaksiUseCase.execute();
    result.fold(
      (failure) => emit(TransaksiError(failure.displayMessage)),
      (data) {
        _allTransaksi = data;
        _emitFiltered();
      },
    );
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    _emitFiltered();
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

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _allTransaksi = [];
    _activeFilter = 'Semua Waktu';
    _searchQuery = '';
    emit(TransaksiInitial());
  }

  void _emitFiltered() {
    List<TransaksiGroupEntity> filteredGroups = [];

    final query = _searchQuery.toLowerCase();

    for (var group in _allTransaksi) {
      if (_activeFilter != 'Semua Waktu' && group.header != _activeFilter && _activeFilter != 'Bulan Ini') {
        continue;
      }

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
      activeFilter: _activeFilter,
      searchQuery: _searchQuery,
    ));
  }
}
