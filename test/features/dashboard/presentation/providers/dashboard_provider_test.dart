import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pilah_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import '../../../../support/stub_api.dart';

void main() {
  test('loads dashboard stats into Riverpod state', () async {
    final api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: {
      'total_nilai_bulan_ini': '1234567',
      'nasabah_aktif': 12,
      'total_sampah_kg_bulan_ini': '3.5',
      'transaksi_bulan_ini': 9,
    });
    final container = ProviderContainer(overrides: [
      dashboardProvider.overrideWith(() => DashboardNotifier(
            GetDashboardStatsUseCase(
              DashboardRepositoryImpl(
                DashboardRemoteDataSourceImpl(api.network),
              ),
            ),
          )),
    ]);
    addTearDown(container.dispose);

    await container.read(dashboardProvider.notifier).loadStats();

    expect(
        container.read(dashboardProvider),
        const DashboardState(
          status: DashboardStatus.loaded,
          totalKasBulanIni: 1234567,
          totalNasabahAktif: 12,
          totalSampahKg: 3.5,
          totalTransaksi: 9,
        ));
  });
}
