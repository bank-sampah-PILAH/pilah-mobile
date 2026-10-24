import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
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
///
/// The origin is set automatically on page open ([muatLokasiAwal]): a
/// previously-picked point wins if one was saved in local storage, otherwise
/// the device fix is tried; both paths then persist whatever a later
/// [pilihDariPeta] puts in its place.
@lazySingleton
class CariBankCubit extends Cubit<CariBankState> {
  final CariBankRemoteDataSource _dataSource;

  // ponytail: null storage when hand-built (tests); DI passes the real one.
  @Named('shared_preferences')
  final AppStorage? storage;

  CariBankCubit(this._dataSource, {@Named('shared_preferences') this.storage})
      : super(const CariBankInitial());

  /// Local-storage keys persisting the last manually picked origin. The
  /// saved point beats the device fix on every page open.
  static const _kunciLat = 'cari_bank_manual_lat';
  static const _kunciLng = 'cari_bank_manual_lng';
  static const _kunciRadius = 'cari_bank_manual_radius';

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

  /// Saves the last manually picked origin so it can win the next page open.
  Future<void> _simpanManual() async {
    final storage = this.storage;
    final pusat = _pusat;
    final radius = _radiusKm;
    if (storage == null || pusat == null || radius == null) return;
    await storage.put(_kunciLat, pusat.latitude);
    await storage.put(_kunciLng, pusat.longitude);
    await storage.put(_kunciRadius, radius);
  }

  /// Default origin on page open (marketplace-style): a saved manual pick
  /// beats the device fix; a device fix becomes the origin too — its radius
  /// default (5 km) stays, only manual picks persist their radius. Either
  /// path just kicks off load; failures degrade into quiet keyword mode.
  Future<void> muatLokasiAwal() async {
    if (_pusat != null) return;
    final storage = this.storage;
    if (storage != null) {
      final lat = await storage.get<double>(_kunciLat);
      final lng = await storage.get<double>(_kunciLng);
      final radius = await storage.get<double>(_kunciRadius);
      if (lat != null && lng != null) {
        _pusat = (latitude: lat, longitude: lng);
        _radiusKm = radius ?? 5;
        _jadwalkanMuat();
        return;
      }
    }
    final lokasi = await di<LocationService>().currentLocation();
    if (_pusat != null || isClosed) return;
    if (lokasi != null) {
      _pusat = lokasi;
      _radiusKm ??= 5;
      _jadwalkanMuat();
    }
  }

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

  /// Uses the map-picker's popped point as the search origin (PIL-314).
  /// A manual pick persists, so the next page open reuses it instead of
  /// jumping back to the device fix.
  Future<void> pilihDariPeta(Lokasi lokasi) async {
    _pusat = lokasi;
    _radiusKm ??= 5;
    await _simpanManual();
    _jadwalkanMuat();
  }

  /// Sets the search radius and reloads; nothing to do when not in mode.
  void pilihRadiusKm(double km) {
    if (_radiusKm == null || _radiusKm == km) return;
    _radiusKm = km;
    _jadwalkanMuat();
  }

  void _jadwalkanMuat() {
    _jeda?.cancel();
    if (isClosed) return;
    _jeda = Timer(jedaPencarian, load);
  }

  /// Loads/fresh-loads the first page with the current `q`/`kota` filters.
  Future<void> load() async {
    _jeda?.cancel();
    final generation = ++_generation;
    _isLoadingMore = false;
    if (isClosed) return;
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
