import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:pilah_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

@lazySingleton
class GetDashboardStatsUseCase implements UseCase<DashboardStats, void> {
  final DashboardRepository repository;

  GetDashboardStatsUseCase(this.repository);

  @override
  Future<Either<NetworkException, DashboardStats>> execute([void args]) {
    return repository.getStats();
  }
}
