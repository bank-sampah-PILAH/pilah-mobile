import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
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

  List<HargaEntity> _allHarga = [];
  bool _isActiveTab = true;
  String _searchQuery = '';

  HargaCubit(
    this.getHargaUseCase,
    this.addHargaUseCase,
    this.updateHargaUseCase,
    this.deactivateHargaUseCase,
  ) : super(HargaInitial());

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  Future<void> loadHarga() async {
    emit(HargaLoading());
    final result = await getHargaUseCase.execute();
    result.fold(
      (failure) => emit(HargaError(failure.message ?? 'Unknown Error')),
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

  Future<void> addHarga(HargaEntity harga) async {
    final result = await addHargaUseCase.execute(harga);
    result.fold(
      (failure) => emit(HargaError(failure.message ?? 'Unknown Error')),
      (_) => loadHarga(),
    );
  }

  Future<void> updateHarga(HargaEntity harga) async {
    final result = await updateHargaUseCase.execute(harga);
    result.fold(
      (failure) => emit(HargaError(failure.message ?? 'Unknown Error')),
      (_) => loadHarga(),
    );
  }

  Future<void> deactivateHarga(String id) async {
    final result = await deactivateHargaUseCase.execute(id);
    result.fold(
      (failure) => emit(HargaError(failure.message ?? 'Unknown Error')),
      (_) => loadHarga(),
    );
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
