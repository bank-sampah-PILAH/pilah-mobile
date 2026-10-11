import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

/// Search state for the cari bank sampah list (PIL-308).
///
/// Mirrors the NasabahCubit page pattern (PIL-214): debounced keyword typing,
/// server pagination through a `hasMore`/`muatBerikutnya` pair, and a request
/// generation so a slow old response cannot overwrite a newer query.
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
  List<BankSampahDirectoryEntity> _items = [];
  int _halaman = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _totalCount = 0;
  int _generation = 0;

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
      func: _dataSource.search(q: _q, kota: _kota, page: 1),
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
      func: _dataSource.search(q: _q, kota: _kota, page: _halaman + 1),
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
        ),
      );
}
