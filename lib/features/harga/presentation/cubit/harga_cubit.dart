import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/dummy_data.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';

class HargaCubit extends Cubit<HargaState> {
  HargaCubit() : super(HargaInitial());

  bool _isActiveTab = true;
  String _searchQuery = '';

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  Future<void> loadHarga() async {
    emit(HargaLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    _emitFiltered();
  }

  void setActiveTab(bool isActive) {
    _isActiveTab = isActive;
    _emitFiltered();
  }

  void searchHarga(String query) {
    _searchQuery = query;
    _emitFiltered();
  }

  void deactivateJenisSampah(String id) {
    final index = DummyData.jenisSampahList.indexWhere((j) => j['id'] == id);
    if (index != -1) {
      DummyData.jenisSampahList[index] = {
        ...DummyData.jenisSampahList[index],
        'isActive': false,
      };
      _emitFiltered();
    }
  }

  void activateJenisSampah(String id) {
    final index = DummyData.jenisSampahList.indexWhere((j) => j['id'] == id);
    if (index != -1) {
      DummyData.jenisSampahList[index] = {
        ...DummyData.jenisSampahList[index],
        'isActive': true,
      };
      _emitFiltered();
    }
  }

  void updateJenisSampah(Map<String, dynamic> updatedData) {
    final id = updatedData['id'];
    final index = DummyData.jenisSampahList.indexWhere((j) => j['id'] == id);
    if (index != -1) {
      DummyData.jenisSampahList[index] = {
        ...DummyData.jenisSampahList[index],
        ...updatedData,
      };
      _emitFiltered();
    }
  }

  void addJenisSampah(Map<String, dynamic> newData) {
    final newId = 'JS-${(DummyData.jenisSampahList.length + 1).toString().padLeft(3, '0')}';
    DummyData.jenisSampahList.add({
      'id': newId,
      'isActive': true,
      ...newData,
    });
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = DummyData.jenisSampahList.where((item) {
      final matchesTab = item['isActive'] == _isActiveTab;
      if (_searchQuery.isEmpty) return matchesTab;

      final query = _searchQuery.toLowerCase();
      final name = (item['name'] as String).toLowerCase();
      final subtitle = (item['subtitle'] as String? ?? '').toLowerCase();
      return matchesTab && (name.contains(query) || subtitle.contains(query));
    }).map((e) => Map<String, dynamic>.from(e)).toList();

    emit(HargaLoaded(
      jenisSampahList: filtered,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    ));
  }
}
