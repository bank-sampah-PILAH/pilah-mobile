import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

@lazySingleton
class NasabahCubit extends Cubit<NasabahState> {
  final GetNasabahUseCase getNasabahUseCase;
  final GetNasabahRingkasanUseCase getNasabahRingkasanUseCase;
  final AddNasabahUseCase addNasabahUseCase;
  final UpdateNasabahUseCase updateNasabahUseCase;
  final ActivateNasabahUseCase activateNasabahUseCase;
  final DeactivateNasabahUseCase deactivateNasabahUseCase;

  List<NasabahEntity> _allNasabah = [];
  bool _isActiveTab = true;
  String _searchQuery = '';

  NasabahCubit(
    this.getNasabahUseCase,
    this.getNasabahRingkasanUseCase,
    this.addNasabahUseCase,
    this.updateNasabahUseCase,
    this.activateNasabahUseCase,
    this.deactivateNasabahUseCase,
  ) : super(NasabahInitial());

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;
  int get activeCount => _allNasabah.where((n) => n.isActive).length;

  Future<void> loadNasabah() async {
    emit(NasabahLoading());
    final result = await getNasabahUseCase.execute();
    result.fold(
      (failure) => emit(NasabahError(failure.displayMessage)),
      (data) {
        _allNasabah = data;
        _emitFiltered();
      },
    );
  }

  void setActiveTab(bool isActive) {
    _isActiveTab = isActive;
    _emitFiltered();
  }

  void searchNasabah(String query) {
    _searchQuery = query;
    _emitFiltered();
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
  Future<NetworkException?> updateNasabah(String id, NasabahRequest request) async {
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

  Future<NasabahRingkasan?> fetchRingkasan(String id) async {
    final result = await getNasabahRingkasanUseCase.execute(id);
    return result.fold((_) => null, (data) => data);
  }

  void _emitFiltered() {
    final filtered = _allNasabah.where((customer) {
      final matchesTab = customer.isActive == _isActiveTab;
      if (_searchQuery.isEmpty) return matchesTab;

      final query = _searchQuery.toLowerCase();
      final name = customer.name.toLowerCase();
      final phone = customer.phone.toLowerCase();
      return matchesTab && (name.contains(query) || phone.contains(query));
    }).toList();

    emit(NasabahLoaded(
      nasabahList: filtered,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    ));
  }
}
