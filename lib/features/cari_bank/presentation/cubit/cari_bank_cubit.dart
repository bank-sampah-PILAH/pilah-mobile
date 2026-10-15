import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/services/di.dart';

/// Search state for the cari bank sampah list (PIL-308).
///
/// Mirrors the NasabahCubit page pattern (PIL-214): debounced keyword typing,
/// server pagination through a `hasMore`/`muatBerikutnya` pair, and a request
/// generation so a slow old response cannot overwrite a newer query.
///
/// PIL-314 adds a location mode: an optional coordinate origin (from the
/// device or the map picker) plus a radius; while it is set every request
/// carries the trio (and optionally sort=radius default) and rows come back
/// with `jarak_km`.
@lazySingleton
class CariBankCubit extends Cubit<CariBankState> {
  final CariBankRemoteDataSource _dataSource;

  CariBankCubit(this._dataSource) : super(const CariBankInitial());

  /// Jeda ketik sebelum pencarian dikirim, supaya satu kata tidak memicu
  /// satu panggilan API per huruf.
  static const Duration jedaPencarian = Duration(milliseconds: 300);

  Timer? _jeda;
  String _q = '';
  String _kota = '';
  Lokasi? _pusat;
  double? _radiusKm;
  List<BankSampahDirectoryEntity> _items = [];
  int _halaman = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _totalCount = 0;
  int _generation = 0;

  /// True while a coordinate origin is active; rows then carry distances.
  bool get modeLokasi => _pusat != null;

  void ketikKataKunci(String nilai) {
    final q = nilai.trim();
    if (q == _q) return;
    _q = q;
    _jadwalkanMuat();
  }

  /// Kota filter — the PIL-329 option-A placeholder, a plain text match.
  void ketikKota(String nilai) {
    final kota = nilai.trim();
    if (kota == _kota) return;
    _kota = kota;
    _jadwalkanMuat();
  }

  /// Uses the device location as the search origin (PIL-314). A denied
  /// permission or missing fix stays in keyword mode silently — no error
  /// burst for something the user never asked to block.
  Future<void> pilihLokasiSaya() async {
    if (_pusat != null) return;
    final lokasi = await di<LocationService>().currentLocation();
    if (lokasi == null || _pusat != null) return;
    _pusat = lokasi;
    _radiusKm ??= 5;
    _jadwalkanMuat();
  }

  /// Uses the map-picker's popped point as the search origin (PIL-314).
  void pilihDariPeta(Lokasi lokasi) {
    _pusat = lokasi;
    _radiusKm ??= 5;
    _jadwalkanMuat();
  }

  /// Sets the search radius and reloads; nothing to do when not in mode.
  void pilihRadiusKm(double km) {
    if (_radiusKm == km) return;
    _radiusKm = km;
    _jadwalkanMuat();
  }

  /// Leaves location mode back to plain keyword search (PIL-314).
  void hapusLokasi() {
    if (_pusat == null) return;
    _pusat = null;
    _radiusKm = null;
    _jadwalkanMuat();
  }

  void _jadwalkanMuat() {
    _jeda?.cancel();
    _jeda = Timer(jedaPencarian, load);
  }

  /// Loads/fresh-loads the first page with the current `q`/`kota` filters.
  Future<void> load() async {
    _jeda?.cancel();
    final generation = ++_generation;
    _isLoadingMore = false;
    if (state is! CariBankLoaded) emit(const CariBankLoading());
    final either = await apiCall<CariBankPage>(
      func: _dataSource.search(
        q: _q,
        kota: _kota,
        page: 1,
        latitude: _pusat?.latitude,
        longitude: _pusat?.longitude,
        radiusKm: _radiusKm,
        sort: _pusat != null ? 'distance' : null,
      ),
      mapper: (value) => value as CariBankPage,
    );
    if (isClosed || generation != _generation) return;
    either.fold(
      (error) => emit(CariBankError(error.displayMessage)),
      (page) {
        _items = page.items;
        _halaman = 1;
        _hasMore = page.hasMore;
        _totalCount = page.totalCount;
        _emitLoaded();
      },
    );
  }

  /// Menyambung halaman berikutnya ke daftar yang sudah tampil. Diam saja bila
  /// halaman terakhir sudah tercapai atau permintaan sebelumnya masih berjalan.
  Future<void> muatBerikutnya() async {
    if (!_hasMore || _isLoadingMore || state is! CariBankLoaded) return;
    final generation = _generation;
    _isLoadingMore = true;
    _emitLoaded();
    final either = await apiCall<CariBankPage>(
      func: _dataSource.search(
        q: _q,
        kota: _kota,
        page: _halaman + 1,
        latitude: _pusat?.latitude,
        longitude: _pusat?.longitude,
        radiusKm: _radiusKm,
        sort: _pusat != null ? 'distance' : null,
      ),
      mapper: (value) => value as CariBankPage,
    );
    if (isClosed || generation != _generation) return;
    _isLoadingMore = false;
    either.fold(
      (error) => emit(
        CariBankError(error.displayMessage),
      ),
      (page) {
        _items = [..._items, ...page.items];
        _halaman += 1;
        _hasMore = page.hasMore;
        _totalCount = page.totalCount;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() => emit(
        CariBankLoaded(
          items: List.unmodifiable(_items),
          hasMore: _hasMore,
          isLoadingMore: _isLoadingMore,
          totalCount: _totalCount,
          searchQuery: _q,
          kotaFilter: _kota,
          dalamRadiusKm: _radiusKm,
        ),
      );
}
