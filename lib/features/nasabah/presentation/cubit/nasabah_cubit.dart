import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

/// Filter tab on the nasabah page. `menunggu` shows pending membership
/// submissions (PIL-188); rejected rows appear in no tab (audit only).
enum NasabahTab { aktif, tidakAktif, menunggu }

@lazySingleton
class NasabahCubit extends Cubit<NasabahState> {
  final GetNasabahUseCase getNasabahUseCase;
  final GetActiveNasabahUseCase getActiveNasabahUseCase;
  final GetNasabahRingkasanUseCase getNasabahRingkasanUseCase;
  final AddNasabahUseCase addNasabahUseCase;
  final UpdateNasabahUseCase updateNasabahUseCase;
  final ActivateNasabahUseCase activateNasabahUseCase;
  final DeactivateNasabahUseCase deactivateNasabahUseCase;
  final ApproveNasabahUseCase approveNasabahUseCase;
  final RejectNasabahUseCase rejectNasabahUseCase;
  final SinkronProfilNasabahUseCase sinkronProfilNasabahUseCase;

  /// Daftar untuk picker Transaksi Baru: seluruh nasabah aktif, tanpa paginasi.
  List<NasabahEntity> _allNasabah = [];

  /// Halaman daftar nasabah yang sedang ditampilkan, hasil paginasi server.
  List<NasabahEntity> _items = [];
  int _halaman = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _totalCount = 0;
  int _totalAktif = 0;
  int _listRequestGeneration = 0;
  int _activeCountRequestGeneration = 0;
  bool _listNeedsReload = false;

  Timer? _jedaCari;

  bool? _isActiveTab = true;
  String _searchQuery = '';

  /// Jeda ketik sebelum pencarian dikirim, supaya satu kata tidak memicu
  /// satu panggilan API per huruf.
  static const Duration jedaPencarian = Duration(milliseconds: 300);

  NasabahCubit(
    this.getNasabahUseCase,
    this.getActiveNasabahUseCase,
    this.getNasabahRingkasanUseCase,
    this.addNasabahUseCase,
    this.updateNasabahUseCase,
    this.activateNasabahUseCase,
    this.deactivateNasabahUseCase,
    this.approveNasabahUseCase,
    this.rejectNasabahUseCase,
    this.sinkronProfilNasabahUseCase,
  ) : super(NasabahInitial());

  /// `true` = aktif, `false` = tidak aktif, `null` = menunggu.
  bool? get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  /// Jumlah nasabah aktif menurut server, bukan sebanyak yang sudah dimuat.
  ///
  /// Menghitung isi daftar akan salah begitu daftarnya berpaginasi.
  int get activeCount => _totalAktif;

  /// Every active nasabah, independent of the nasabah page's active/inactive
  /// tab and search query. The Transaksi Baru picker reads this so its options
  /// aren't narrowed by whatever the nasabah page was last showing.
  List<NasabahEntity> get activeNasabah =>
      _allNasabah.where((n) => n.isActive && n.status == 'approved').toList();

  /// Fetches the nasabah list, preserving the current tab and search query.
  ///
  /// Existing rows stay visible while the first page reloads. Pass [silent]
  /// when pull-to-refresh already shows its own indicator. Without loaded data,
  /// a real [NasabahLoading] state is emitted.
  Future<void> loadNasabah({bool silent = false}) async {
    _jedaCari?.cancel();
    final requestGeneration = ++_listRequestGeneration;
    _listNeedsReload = false;
    final hasLoadedList = state is NasabahLoaded;
    _halaman = 1;
    _isLoadingMore = false;
    if (!silent || !hasLoadedList) {
      if (hasLoadedList) {
        _emitLoaded(isReloading: true);
      } else {
        emit(NasabahLoading(isActiveTab: _isActiveTab));
      }
    }
    final activeCountRequestGeneration =
        _isActiveTab == true && _searchQuery.isEmpty
            ? ++_activeCountRequestGeneration
            : null;
    final result = await getNasabahUseCase.execute(_params(1));
    if (isClosed || requestGeneration != _listRequestGeneration) return;
    result.fold(
      (failure) => emit(NasabahError(failure.displayMessage)),
      (data) {
        _items = data.items;
        _hasMore = data.hasMore;
        _totalCount = data.totalCount;
        if (activeCountRequestGeneration != null &&
            activeCountRequestGeneration == _activeCountRequestGeneration) {
          _totalAktif = data.totalCount;
        }
        _emitLoaded();
      },
    );
  }

  /// Menyambung halaman berikutnya ke daftar yang sudah tampil.
  ///
  /// Diam saja bila halaman terakhir sudah tercapai atau permintaan sebelumnya
  /// masih berjalan, supaya menggulir cepat tidak memanggil API berkali-kali.
  Future<void> loadMoreNasabah() async {
    if (_listNeedsReload ||
        !_hasMore ||
        _isLoadingMore ||
        state is! NasabahLoaded ||
        (state as NasabahLoaded).isReloading ||
        (state as NasabahLoaded).isActiveTab != _isActiveTab ||
        (state as NasabahLoaded).searchQuery != _searchQuery) {
      return;
    }
    final requestGeneration = _listRequestGeneration;
    _isLoadingMore = true;
    _emitLoaded();

    final berikutnya = _halaman + 1;
    final result = await getNasabahUseCase.execute(_params(berikutnya));
    if (isClosed || requestGeneration != _listRequestGeneration) return;
    _isLoadingMore = false;
    result.fold(
      // Halaman yang sudah tampil dipertahankan; kegagalan menyambung tidak
      // boleh mengosongkan layar yang sedang dibaca pengurus.
      (failure) => _emitLoaded(),
      (data) {
        _halaman = berikutnya;
        _items = [..._items, ...data.items];
        _hasMore = data.hasMore;
        _totalCount = data.totalCount;
        _emitLoaded();
      },
    );
  }

  GetNasabahParams _params(int halaman) => GetNasabahParams(
        page: halaman,
        status: _statusParam,
        // Server mengabaikan kata kunci di bawah dua huruf, jadi jangan dikirim.
        search: _searchQuery.length >= 2 ? _searchQuery : null,
      );

  String get _statusParam {
    if (_isActiveTab == null) return 'menunggu';
    return _isActiveTab! ? 'aktif' : 'tidak_aktif';
  }

  /// Memuat seluruh nasabah aktif untuk picker Transaksi Baru.
  ///
  /// Dipisah dari [loadNasabah] karena halaman daftar nasabah berpaginasi,
  /// sedangkan picker harus menampilkan semua pilihan sekaligus (PIL-214).
  Future<List<NasabahEntity>> loadActiveNasabah() async {
    final result = await getActiveNasabahUseCase.execute();
    return result.fold((failure) => throw failure, (data) {
      _allNasabah = data.items;
      return activeNasabah;
    });
  }

  Future<void> _refreshActiveCount() async {
    final requestGeneration = ++_activeCountRequestGeneration;
    final result = await getNasabahUseCase.execute(
      const GetNasabahParams(status: 'aktif'),
    );
    if (isClosed || requestGeneration != _activeCountRequestGeneration) return;
    result.fold((_) {}, (data) {
      _totalAktif = data.totalCount;
      if (state is NasabahLoaded) _emitLoaded();
    });
  }

  Future<void> _reloadAfterMutation() async {
    await loadNasabah();
    if (_isActiveTab != true || _searchQuery.isNotEmpty) {
      await _refreshActiveCount();
    }
  }

  Future<void> setActiveTab(bool? isActive) async {
    if (_isActiveTab == isActive) return;
    _isActiveTab = isActive;
    await loadNasabah();
  }

  /// Mengirim kata kunci ke server setelah pengurus berhenti mengetik.
  ///
  /// Pencarian harus dilakukan server karena menyaring di aplikasi hanya akan
  /// menyaring halaman yang kebetulan sudah dimuat.
  void searchNasabah(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _listRequestGeneration++;
    _listNeedsReload = true;
    _isLoadingMore = false;
    _jedaCari?.cancel();
    _jedaCari = Timer(jedaPencarian, loadNasabah);
  }

  @override
  Future<void> close() {
    _jedaCari?.cancel();
    return super.close();
  }

  /// Creates a nasabah. Returns `null` on success (list reloaded), otherwise the
  /// [NetworkException] so the form can surface field-level backend errors.
  Future<NetworkException?> addNasabah(NasabahRequest request) async {
    final result = await addNasabahUseCase.execute(request);
    return result.fold((failure) async => failure, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  /// Updates a nasabah. Returns `null` on success, otherwise the exception.
  Future<NetworkException?> updateNasabah(
      String id, NasabahRequest request) async {
    final result = await updateNasabahUseCase.execute(
      UpdateNasabahParams(id: id, request: request),
    );
    return result.fold((failure) async => failure, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  /// Toggles active status. Returns `null` on success, otherwise the exception.
  Future<NetworkException?> setNasabahStatus(String id, bool activate) async {
    final result = activate
        ? await activateNasabahUseCase.execute(id)
        : await deactivateNasabahUseCase.execute(id);
    return result.fold((failure) async => failure, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  /// Approves or rejects a pending membership submission (PIL-188). Returns
  /// `null` on success, otherwise the exception.
  Future<NetworkException?> decideNasabah(
    String id, {
    required bool approve,
    String? catatan,
  }) async {
    final params = DecideNasabahParams(id: id, catatan: catatan);
    final result = approve
        ? await approveNasabahUseCase.execute(params)
        : await rejectNasabahUseCase.execute(params);
    return result.fold((failure) async => failure, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  /// Menyamakan catatan nasabah dengan profil akunnya sendiri. Returns `null`
  /// on success (list reloaded), otherwise the [NetworkException].
  Future<NetworkException?> sinkronProfil(String id) async {
    final result = await sinkronProfilNasabahUseCase.execute(id);
    return result.fold((failure) async => failure, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  Future<NasabahRingkasan?> fetchRingkasan(String id) async {
    final result = await getNasabahRingkasanUseCase.execute(id);
    return result.fold((_) => null, (data) => data);
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _jedaCari?.cancel();
    _listRequestGeneration++;
    _activeCountRequestGeneration++;
    _listNeedsReload = false;
    _allNasabah = [];
    _items = [];
    _halaman = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _totalCount = 0;
    _totalAktif = 0;
    _isActiveTab = true;
    _searchQuery = '';
    emit(NasabahInitial());
  }

  void _emitLoaded({bool isReloading = false}) {
    emit(NasabahLoaded(
      nasabahList: _items,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
      isReloading: isReloading,
      totalCount: _totalCount,
    ));
  }
}
