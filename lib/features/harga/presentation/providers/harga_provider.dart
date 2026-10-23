import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';

final hargaProvider = NotifierProvider<HargaNotifier, HargaState>(
  () => HargaNotifier(
    di<GetHargaUseCase>(),
    di<AddHargaUseCase>(),
    di<UpdateHargaUseCase>(),
    di<DeactivateHargaUseCase>(),
    di<ActivateHargaUseCase>(),
    di<UbahHargaUseCase>(),
  ),
);

class HargaNotifier extends Notifier<HargaState> {
  final GetHargaUseCase getHargaUseCase;
  final AddHargaUseCase addHargaUseCase;
  final UpdateHargaUseCase updateHargaUseCase;
  final DeactivateHargaUseCase deactivateHargaUseCase;
  final ActivateHargaUseCase activateHargaUseCase;
  final UbahHargaUseCase ubahHargaUseCase;

  List<HargaEntity> _allHarga = [];
  int _permintaanTerakhir = 0;
  bool _isActiveTab = true;
  String _searchQuery = '';

  HargaNotifier(
    this.getHargaUseCase,
    this.addHargaUseCase,
    this.updateHargaUseCase,
    this.deactivateHargaUseCase,
    this.activateHargaUseCase,
    this.ubahHargaUseCase,
  );

  @override
  HargaState build() => HargaInitial();

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
  /// into skeletons underneath it. [silent] only applies when there is data to
  /// keep: from [HargaInitial] or [HargaError] there is nothing on screen, so a
  /// real loading state is emitted regardless.
  Future<void> loadHarga({bool silent = false}) async {
    final permintaan = ++_permintaanTerakhir;
    if (!silent || state is! HargaLoaded) state = HargaLoading();
    final result = await getHargaUseCase.execute();
    // Reload yang lebih baru sudah berjalan: jawaban ini sudah usang.
    if (!ref.mounted || permintaan != _permintaanTerakhir) return;
    result.fold(
      (failure) => state = HargaError(failure.displayMessage),
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

  /// Mengganti harga, sekarang atau terjadwal. Returns `null` on success
  /// (list reloaded), otherwise the exception so the form can show it.
  Future<NetworkException?> ubahHarga(UbahHarga perubahan) async {
    final result = await ubahHargaUseCase.execute(perubahan);
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
    state = HargaInitial();
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

    state = HargaLoaded(
      jenisSampahList: filtered,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    );
  }
}
