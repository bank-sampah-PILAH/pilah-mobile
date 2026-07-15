import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<NetworkException, DashboardStats>> getStats();
}
