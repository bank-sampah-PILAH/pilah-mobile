import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/dummy_data.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_state.dart';

class TransaksiCubit extends Cubit<TransaksiState> {
  TransaksiCubit() : super(TransaksiInitial());

  String _activeFilter = 'Hari Ini';
  String _searchQuery = '';

  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  Future<void> loadTransaksi() async {
    emit(TransaksiLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    _emitFiltered();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    _emitFiltered();
  }

  void searchTransaksi(String query) {
    _searchQuery = query;
    _emitFiltered();
  }

  void tambahTransaksi(Map<String, dynamic> newTx, String customerId, int totalAmount) {
    // 1. Add new transaction to the top of 'HARI INI'
    final hariIniIndex = DummyData.transaksiList.indexWhere((g) => g['header'] == 'HARI INI');
    if (hariIniIndex != -1) {
      final transactions = List<Map<String, dynamic>>.from(DummyData.transaksiList[hariIniIndex]['transactions']);
      transactions.insert(0, newTx);
      DummyData.transaksiList[hariIniIndex] = {
        ...DummyData.transaksiList[hariIniIndex],
        'transactions': transactions,
      };
    } else {
      DummyData.transaksiList.insert(0, {
        'header': 'HARI INI',
        'transactions': [newTx],
      });
    }

    // 2. Update customer balance
    final customerIndex = DummyData.nasabahList.indexWhere((n) => n['id'] == customerId);
    if (customerIndex != -1) {
      final customer = DummyData.nasabahList[customerIndex];
      // Convert "Rp 450.000" to int 450000
      final balanceStr = (customer['balance'] as String).replaceAll(RegExp(r'[^0-9]'), '');
      final currentBalance = int.tryParse(balanceStr) ?? 0;
      final newBalance = currentBalance + totalAmount;
      
      // Format back to "Rp XXX.XXX"
      final newBalanceStr = 'Rp ${newBalance.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]}.')}';
      
      DummyData.nasabahList[customerIndex] = {
        ...customer,
        'balance': newBalanceStr,
      };
    }

    // 3. Refresh list
    loadTransaksi();
  }

  void _emitFiltered() {
    // Deep copy and filter logic
    final query = _searchQuery.toLowerCase();
    
    List<Map<String, dynamic>> filteredGroups = [];
    
    for (var group in DummyData.transaksiList) {
      final transactions = (group['transactions'] as List<dynamic>).map((t) {
        return Map<String, dynamic>.from(t as Map<String, dynamic>);
      }).where((t) {
        if (query.isEmpty) return true;
        final name = (t['name'] as String).toLowerCase();
        return name.contains(query);
      }).toList();
      
      if (transactions.isNotEmpty) {
        filteredGroups.add({
          'header': group['header'],
          'transactions': transactions,
        });
      }
    }

    emit(TransaksiLoaded(
      transaksiList: filteredGroups,
      activeFilter: _activeFilter,
      searchQuery: _searchQuery,
    ));
  }
}
