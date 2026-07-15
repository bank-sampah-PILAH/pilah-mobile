import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';

@lazySingleton
class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardStatsUseCase getDashboardStatsUseCase;

  DashboardCubit(this.getDashboardStatsUseCase) : super(const DashboardState());

  /// Loads the current-month metrics from `GET /dashboard/stats`. The backend
  /// computes these authoritatively, so figures like Total Kas / Total Sampah
  /// are correct instead of being (mis)derived from the paginated list.
  ///
  /// Pass [silent] to skip the loading emit — pull-to-refresh already shows a
  /// spinner, so the stat cards should keep their figures instead of collapsing
  /// into skeletons underneath it.
  Future<void> loadStats({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: DashboardStatus.loading, error: null));
    }
    final result = await getDashboardStatsUseCase.execute();
    result.fold(
      (failure) => emit(state.copyWith(
        status: DashboardStatus.error,
        error: failure.displayMessage,
      )),
      (stats) => emit(DashboardState(
        status: DashboardStatus.loaded,
        totalKasBulanIni: stats.totalKasBulanIni,
        totalNasabahAktif: stats.nasabahAktif,
        totalSampahKg: stats.totalSampahKg,
        totalTransaksi: stats.transaksiBulanIni,
      )),
    );
  }

  /// Clears stats to the initial state (used on logout).
  void reset() => emit(const DashboardState());
}
