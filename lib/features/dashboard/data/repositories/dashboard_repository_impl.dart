import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:pilah_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

@LazySingleton(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, DashboardStats>> getStats() {
    return apiCall<DashboardStats>(
      func: remoteDataSource.getStats(),
      mapper: (result) => result as DashboardStats,
    );
  }
}
