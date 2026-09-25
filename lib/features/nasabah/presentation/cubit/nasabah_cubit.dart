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

  /// Daftar untuk picker Transaksi Baru: seluruh nasabah aktif, tanpa paginasi.
  List<NasabahEntity> _allNasabah = [];

  /// Halaman daftar nasabah yang sedang ditampilkan, hasil paginasi server.
  List<NasabahEntity> _items = [];

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
  ) : super(NasabahInitial());

  /// `true` = aktif, `false` = tidak aktif, `null` = menunggu.
  bool? get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;
  int get activeCount =>
      _items.where((n) => n.isActive && n.status == 'approved').length;

  /// Every active nasabah, independent of the nasabah page's active/inactive
  /// tab and search query. The Transaksi Baru picker reads this so its options
  /// aren't narrowed by whatever the nasabah page was last showing.
  List<NasabahEntity> get activeNasabah =>
      _allNasabah.where((n) => n.isActive && n.status == 'approved').toList();

  /// Fetches the nasabah list, preserving the current tab and search query.
  ///
  /// Pass [silent] to skip the [NasabahLoading] emit — pull-to-refresh already
  /// shows a spinner, so the list should stay on screen instead of collapsing
  /// into skeletons underneath it. [silent] only applies when there is data to
  /// keep: from [NasabahInitial] or [NasabahError] there is nothing on screen,
  /// so a real loading state is emitted regardless.
  Future<void> loadNasabah({bool silent = false}) async {
    if (!silent || state is! NasabahLoaded) emit(NasabahLoading());
    final result = await getNasabahUseCase.execute(_params(1));
    result.fold(
      (failure) => emit(NasabahError(failure.displayMessage)),
      (data) {
        _items = data.items;
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
  Future<void> loadActiveNasabah() async {
    if (state is! NasabahLoaded) emit(NasabahLoading());
    final result = await getActiveNasabahUseCase.execute();
    result.fold(
      (failure) => emit(NasabahError(failure.displayMessage)),
      (data) {
        _allNasabah = data.items;
        emit(NasabahLoaded(
          nasabahList: activeNasabah,
          isActiveTab: _isActiveTab,
          searchQuery: _searchQuery,
        ));
      },
    );
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
    _searchQuery = query;
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
    return result.fold(
      (failure) => failure,
      (_) {
        loadNasabah();
        return null;
      },
    );
  }

  /// Updates a nasabah. Returns `null` on success, otherwise the exception.
  Future<NetworkException?> updateNasabah(
      String id, NasabahRequest request) async {
    final result = await updateNasabahUseCase.execute(
      UpdateNasabahParams(id: id, request: request),
    );
    return result.fold(
      (failure) => failure,
      (_) {
        loadNasabah();
        return null;
      },
    );
  }

  /// Toggles active status. Returns `null` on success, otherwise the exception.
  Future<NetworkException?> setNasabahStatus(String id, bool activate) async {
    final result = activate
        ? await activateNasabahUseCase.execute(id)
        : await deactivateNasabahUseCase.execute(id);
    return result.fold(
      (failure) => failure,
      (_) {
        loadNasabah();
        return null;
      },
    );
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
    return result.fold(
      (failure) => failure,
      (_) {
        loadNasabah();
        return null;
      },
    );
  }

  Future<NasabahRingkasan?> fetchRingkasan(String id) async {
    final result = await getNasabahRingkasanUseCase.execute(id);
    return result.fold((_) => null, (data) => data);
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() {
    _allNasabah = [];
    _isActiveTab = true;
    _searchQuery = '';
    emit(NasabahInitial());
  }

  void _emitLoaded() {
    emit(NasabahLoaded(
      nasabahList: _items,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    ));
  }
}
