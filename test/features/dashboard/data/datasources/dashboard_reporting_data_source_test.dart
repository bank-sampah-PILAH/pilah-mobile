import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

class _NetworkService extends Mock implements NetworkService {}

void main() {
  late _NetworkService network;
  late DashboardReportingDataSourceImpl source;

  setUp(() {
    network = _NetworkService();
    source = DashboardReportingDataSourceImpl(network);
  });

  test('operational trends sends range and granularity and maps both measures',
      () async {
    when(() => network.get(
          '/api/v1/dashboard/operational-trends',
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'granularity': 'week',
            'buckets': [
              {
                'period_start': '2026-06-01',
                'setoran_total_nilai': '1250.50',
                'setoran_count': 3,
                'pencairan_total_nominal': '200.00',
                'pencairan_count': 1,
              },
            ],
          },
        ));

    final result = await source.getOperationalTrends(
      range: DashboardReportRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      granularity: TrendGranularity.week,
    );

    verify(() => network.get(
          '/api/v1/dashboard/operational-trends',
          queryParams: {
            'start_date': '2026-06-01',
            'end_date': '2026-06-30',
            'granularity': 'week',
          },
        )).called(1);
    expect(result.single.depositAmount, 1250.5);
    expect(result.single.depositCount, 3);
    expect(result.single.withdrawalAmount, 200);
    expect(result.single.withdrawalCount, 1);
  });

  test('waste categories sends range and maps weight and deposit count',
      () async {
    when(() => network.get(
          '/api/v1/dashboard/waste-categories',
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'categories': [
              {
                'category': 'plastik',
                'total_weight_kg': '12.750',
                'deposit_count': 4,
              },
            ],
          },
        ));

    final result = await source.getWasteCategories(
      range: DashboardReportRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
    );

    verify(() => network.get(
          '/api/v1/dashboard/waste-categories',
          queryParams: {
            'start_date': '2026-06-01',
            'end_date': '2026-06-30',
          },
        )).called(1);
    expect(result.single.category, 'plastik');
    expect(result.single.totalWeightKg, 12.75);
    expect(result.single.depositCount, 4);
  });
}
