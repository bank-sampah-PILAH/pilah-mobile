import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';

@lazySingleton
class HargaCubit extends Cubit<HargaState> {
  final GetHargaUseCase getHargaUseCase;
  final AddHargaUseCase addHargaUseCase;
  final UpdateHargaUseCase updateHargaUseCase;
  final DeactivateHargaUseCase deactivateHargaUseCase;
  final ActivateHargaUseCase activateHargaUseCase;

  List<HargaEntity> _allHarga = [];
  bool _isActiveTab = true;
  String _searchQuery = '';

  HargaCubit(
    this.getHargaUseCase,
    this.addHargaUseCase,
    this.updateHargaUseCase,
    this.deactivateHargaUseCase,
    this.activateHargaUseCase,
  ) : super(HargaInitial());

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  /// Every active jenis sampah, independent of the price-list page's
  /// active/inactive tab and search query. The Transaksi Baru dropdown reads
  /// this so its options aren't narrowed by the price-list page's current view.
  List<HargaEntity> get activeJenisSampah =>
      _allHarga.where((item) => item.isActive).toList();

  /// Fetches the jenis sampah list, preserving the current tab and search query.
  ///
  /// Pass [silent] to skip the [HargaLoading] emit — pull-to-refresh already
  /// shows a spinner, so the list should stay on screen instead of collapsing
  /// into skeletons underneath it.
  Future<void> loadHarga({bool silent = false}) async {
    if (!silent) emit(HargaLoading());
    final result = await getHargaUseCase.execute();
    result.fold(
      (failure) => emit(HargaError(failure.displayMessage)),
      (data) {
        _allHarga = data;
        _emitFiltered();
      },
    );
  }

  void setActiveTab(bool isActive) {
    _isActiveTab = isActive;
    _emitFiltered();
  }

  void searchHarga(String query) {
    _searchQuery = query;
    _emitFiltered();
  }

  /// Creates a jenis sampah. Returns `null` on success (list reloaded),
  /// otherwise the [NetworkException] so the form can surface field errors.
  Future<NetworkException?> addHarga(HargaEntity harga) async {
    final result = await addHargaUseCase.execute(harga);
    return result.fold(
      (failure) => failure,
      (_) {
        loadHarga();
        return null;
      },
    );
  }

  /// Updates a jenis sampah. Returns `null` on success, otherwise the exception.
  Future<NetworkException?> updateHarga(HargaEntity harga) async {
    final result = await updateHargaUseCase.execute(harga);
    return result.fold(
      (failure) => failure,
      (_) {
        loadHarga();
        return null;
      },
    );
  }

  Future<NetworkException?> deactivateHarga(String id) async {
    final result = await deactivateHargaUseCase.execute(id);
    return result.fold(
      (failure) => failure,
      (_) {
        loadHarga();
        return null;
      },
    );
  }

  Future<NetworkException?> activateHarga(String id) async {
    final result = await activateHargaUseCase.execute(id);
    return result.fold(
      (failure) => failure,
      (_) {
        loadHarga();
        return null;
      },
    );
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _allHarga = [];
    _isActiveTab = true;
    _searchQuery = '';
    emit(HargaInitial());
  }

  void _emitFiltered() {
    final filtered = _allHarga.where((item) {
      final matchesTab = item.isActive == _isActiveTab;
      if (_searchQuery.isEmpty) return matchesTab;

      final query = _searchQuery.toLowerCase();
      final name = item.name.toLowerCase();
      final category = item.category.toLowerCase();
      return matchesTab && (name.contains(query) || category.contains(query));
    }).toList();

    emit(HargaLoaded(
      jenisSampahList: filtered,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    ));
  }
}
