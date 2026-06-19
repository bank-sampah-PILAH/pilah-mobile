import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

@lazySingleton
class NasabahCubit extends Cubit<NasabahState> {
  final GetNasabahUseCase getNasabahUseCase;
  final ActivateNasabahUseCase activateNasabahUseCase;
  final DeactivateNasabahUseCase deactivateNasabahUseCase;

  List<NasabahEntity> _allNasabah = [];
  bool _isActiveTab = true;
  String _searchQuery = '';

  NasabahCubit(
    this.getNasabahUseCase,
    this.activateNasabahUseCase,
    this.deactivateNasabahUseCase,
  ) : super(NasabahInitial());

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  Future<void> loadNasabah() async {
    emit(NasabahLoading());
    final result = await getNasabahUseCase.execute();
    result.fold(
      (failure) => emit(NasabahError(failure.message ?? 'Unknown Error')),
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

  Future<void> activateNasabah(String id) async {
    final result = await activateNasabahUseCase.execute(id);
    result.fold(
      (failure) => emit(NasabahError(failure.message ?? 'Unknown Error')),
      (_) => loadNasabah(), // reload data from source
    );
  }

  Future<void> deactivateNasabah(String id) async {
    final result = await deactivateNasabahUseCase.execute(id);
    result.fold(
      (failure) => emit(NasabahError(failure.message ?? 'Unknown Error')),
      (_) => loadNasabah(), // reload data from source
    );
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
