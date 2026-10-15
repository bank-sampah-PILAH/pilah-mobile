import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

abstract class DashboardReportingDataSource {
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  });
  Future<List<WasteCategoryTotal>> getWasteCategories({
    required DashboardReportRange range,
  });
}

@LazySingleton(as: DashboardReportingDataSource)
class DashboardReportingDataSourceImpl implements DashboardReportingDataSource {
  final NetworkService networkService;

  DashboardReportingDataSourceImpl(this.networkService);

  @override
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  }) async {
    final response = await networkService.get(
      '/api/v1/dashboard/operational-trends',
      queryParams: {
        'start_date': reportDate(range.start),
        'end_date': reportDate(range.end),
        'granularity': granularity.name,
      },
    );
    final json = response.data as Map<String, dynamic>;
    return (json['buckets'] as List<dynamic>).map((item) {
      final bucket = item as Map<String, dynamic>;
      return OperationalTrendBucket(
        periodStart: DateTime.parse(bucket['period_start'].toString()),
        depositAmount: _toDouble(bucket['setoran_total_nilai']),
        depositCount: _toInt(bucket['setoran_count']),
        withdrawalAmount: _toDouble(bucket['pencairan_total_nominal']),
        withdrawalCount: _toInt(bucket['pencairan_count']),
      );
    }).toList();
  }

  @override
  Future<List<WasteCategoryTotal>> getWasteCategories({
    required DashboardReportRange range,
  }) async {
    final response = await networkService.get(
      '/api/v1/dashboard/waste-categories',
      queryParams: {
        'start_date': reportDate(range.start),
        'end_date': reportDate(range.end),
      },
    );
    final json = response.data as Map<String, dynamic>;
    return (json['categories'] as List<dynamic>).map((item) {
      final category = item as Map<String, dynamic>;
      return WasteCategoryTotal(
        category: category['category'].toString(),
        totalWeightKg: _toDouble(category['total_weight_kg']),
        depositCount: _toInt(category['deposit_count']),
      );
    }).toList();
  }

  double _toDouble(dynamic value) => double.parse(value.toString());
  int _toInt(dynamic value) => int.parse(value.toString());
}
