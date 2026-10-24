import 'package:flutter_riverpod/flutter_riverpod.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pilah_mobile/services/di.dart';

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  () => DashboardNotifier(di<GetDashboardStatsUseCase>()),
);

class DashboardNotifier extends Notifier<DashboardState> {
  DashboardNotifier(this.getDashboardStatsUseCase);

  final GetDashboardStatsUseCase getDashboardStatsUseCase;

  @override
  DashboardState build() => const DashboardState();

  /// Loads the current-month metrics from the backend. Keep existing figures
  /// visible during a silent pull-to-refresh.
  Future<void> loadStats({bool silent = false}) async {
    if (!silent || state.status != DashboardStatus.loaded) {
      state = state.copyWith(status: DashboardStatus.loading, error: null);
    }
    final result = await getDashboardStatsUseCase.execute();
    result.fold(
      (failure) => state = state.copyWith(
        status: DashboardStatus.error,
        error: failure.displayMessage,
      ),
      (stats) => state = DashboardState(
        status: DashboardStatus.loaded,
        totalKasBulanIni: stats.totalKasBulanIni,
        totalNasabahAktif: stats.nasabahAktif,
        totalSampahKg: stats.totalSampahKg,
        totalTransaksi: stats.transaksiBulanIni,
      ),
    );
  }

  void reset() => state = const DashboardState();
}
