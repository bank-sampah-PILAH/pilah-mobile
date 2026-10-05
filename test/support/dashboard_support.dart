import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pilah_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import 'stub_api.dart';

/// A real [DashboardCubit] over the real dashboard stack, with only HTTP stubbed.
DashboardCubit buildDashboardCubit(StubApi api) =>
    DashboardCubit(GetDashboardStatsUseCase(
        DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(api.network))));
