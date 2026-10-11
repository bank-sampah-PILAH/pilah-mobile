import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';

class _ReportingDataSource implements DashboardReportingDataSource {
  List<OperationalTrendBucket> trends = const [];
  List<WasteCategoryTotal> categories = const [];
  Object? trendError;
  Object? categoryError;

  @override
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  }) async {
    if (trendError case final error?) throw error;
    return trends;
  }

  @override
  Future<List<WasteCategoryTotal>> getWasteCategories({
    required DashboardReportRange range,
  }) async {
    if (categoryError case final error?) throw error;
    return categories;
  }
}

void main() {
  testWidgets('trend widget labels amount and count separately',
      (tester) async {
    final source = _ReportingDataSource()
      ..trends = [
        OperationalTrendBucket(
          periodStart: DateTime(2026, 6),
          depositAmount: 120,
          depositCount: 3,
          withdrawalAmount: 40,
          withdrawalCount: 1,
        ),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: OperationalTrendsWidget(dataSource: source)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nilai setoran dan pencairan (Rp)'), findsOneWidget);
    expect(
        find.text('Jumlah setoran dan pencairan (transaksi)'), findsOneWidget);
    expect(find.text('Hari'), findsOneWidget);
  });

  testWidgets('category widget ranks by weight and displays kg and count',
      (tester) async {
    final source = _ReportingDataSource()
      ..categories = const [
        WasteCategoryTotal(
            category: 'Plastik', totalWeightKg: 2, depositCount: 3),
        WasteCategoryTotal(
            category: 'Kertas', totalWeightKg: 8, depositCount: 1),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WasteCategoriesWidget(dataSource: source)),
    ));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Kertas')).dy,
        lessThan(tester.getTopLeft(find.text('Plastik')).dy));
    expect(find.text('8 kg'), findsOneWidget);
    expect(find.text('1 setoran'), findsOneWidget);
  });

  testWidgets('empty and failed reports have independent feedback',
      (tester) async {
    final source = _ReportingDataSource()..categoryError = Exception('offline');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Expanded(child: OperationalTrendsWidget(dataSource: source)),
          Expanded(child: WasteCategoriesWidget(dataSource: source)),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada data'), findsOneWidget);
    expect(find.text('Gagal memuat kategori'), findsOneWidget);
  });
}
