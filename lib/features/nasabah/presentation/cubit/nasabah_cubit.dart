import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/dummy_data.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class NasabahCubit extends Cubit<NasabahState> {
  NasabahCubit() : super(NasabahInitial());

  bool _isActiveTab = true;
  String _searchQuery = '';

  bool get isActiveTab => _isActiveTab;
  String get searchQuery => _searchQuery;

  Future<void> loadNasabah() async {
    emit(NasabahLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    _emitFiltered();
  }

  void setActiveTab(bool isActive) {
    _isActiveTab = isActive;
    _emitFiltered();
  }

  void searchNasabah(String query) {
    _searchQuery = query;
    _emitFiltered();
  }

  void activateNasabah(String id) {
    final index = DummyData.nasabahList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      DummyData.nasabahList[index] = {
        ...DummyData.nasabahList[index],
        'isActive': true,
      };
      _emitFiltered();
    }
  }

  void deactivateNasabah(String id) {
    final index = DummyData.nasabahList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      DummyData.nasabahList[index] = {
        ...DummyData.nasabahList[index],
        'isActive': false,
      };
      _emitFiltered();
    }
  }

  void _emitFiltered() {
    final filtered = DummyData.nasabahList.where((customer) {
      final matchesTab = customer['isActive'] == _isActiveTab;
      if (_searchQuery.isEmpty) return matchesTab;

      final query = _searchQuery.toLowerCase();
      final name = (customer['name'] as String).toLowerCase();
      final phone = (customer['phone'] as String).toLowerCase();
      return matchesTab && (name.contains(query) || phone.contains(query));
    }).toList();

    emit(NasabahLoaded(
      nasabahList: filtered,
      isActiveTab: _isActiveTab,
      searchQuery: _searchQuery,
    ));
  }
}
