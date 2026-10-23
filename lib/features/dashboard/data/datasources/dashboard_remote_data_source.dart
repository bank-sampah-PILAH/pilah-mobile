import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getStats();
}

@LazySingleton(as: DashboardRemoteDataSource)
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final NetworkService networkService;

  DashboardRemoteDataSourceImpl(this.networkService);

  @override
  Future<DashboardStats> getStats() async {
    final response = await networkService.get(Endpoints.dashboardStats);
    final json = response.data as Map<String, dynamic>;
    return DashboardStats(
      totalSaldoNasabah: _savings(json['total_saldo_nasabah']),
      totalKasBulanIni: _toInt(json['total_nilai_bulan_ini']),
      nasabahAktif: _toInt(json['nasabah_aktif']),
      totalSampahKg: _toDouble(json['total_sampah_kg_bulan_ini']),
      transaksiBulanIni: _toInt(json['transaksi_bulan_ini']),
    );
  }

  // The API sends whole rupiah as an integer string. Reject unsupported or
  // imprecise values rather than silently displaying a misleading zero on web.
  int? _savings(Object? value) {
    final raw = value?.toString() ?? '';
    if (!RegExp(r'^-?\d+$').hasMatch(raw)) return null;
    final amount = int.tryParse(raw);
    if (amount == null || amount.abs() > 9007199254740991) return null;
    return amount;
  }

  int _toInt(dynamic value) =>
      (double.tryParse(value?.toString() ?? '') ?? 0).round();

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
