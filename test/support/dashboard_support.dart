import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pilah_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';

import 'stub_api.dart';

GetDashboardStatsUseCase buildDashboardStatsUseCase(StubApi api) =>
    GetDashboardStatsUseCase(
      DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(api.network)),
    );

DashboardNotifier buildDashboardNotifier(StubApi api) =>
    DashboardNotifier(buildDashboardStatsUseCase(api));

DashboardNotifier buildEmptyDashboardNotifier(StubApi api) =>
    _EmptyDashboardNotifier(buildDashboardNotifier(api));

class _EmptyDashboardNotifier extends DashboardNotifier {
  _EmptyDashboardNotifier(DashboardNotifier source)
      : super(source.getDashboardStatsUseCase);

  @override
  DashboardState build() => const DashboardState();

  @override
  Future<void> loadStats({bool silent = false}) async {}
}
