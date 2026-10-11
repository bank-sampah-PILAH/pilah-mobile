import 'package:fl_chart/fl_chart.dart';
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
  final requestedTrendRanges = <DashboardReportRange>[];
  final requestedCategoryRanges = <DashboardReportRange>[];

  @override
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  }) async {
    requestedTrendRanges.add(range);
    if (trendError case final error?) throw error;
    return trends;
  }

  @override
  Future<List<WasteCategoryTotal>> getWasteCategories({
    required DashboardReportRange range,
  }) async {
    requestedCategoryRanges.add(range);
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

  testWidgets('shared report section applies one selected date range to both',
      (tester) async {
    final source = _ReportingDataSource()
      ..trends = [
        OperationalTrendBucket(
          periodStart: DateTime(2026, 6, 1),
          depositAmount: 1,
          depositCount: 1,
          withdrawalAmount: 0,
          withdrawalCount: 0,
        ),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardReportsSection(
            dataSource: source,
            initialRange: DashboardReportRange(
              start: DateTime(2026, 6, 1),
              end: DateTime(2026, 6, 30),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(source.requestedTrendRanges.single.start, DateTime(2026, 6, 1));
    expect(source.requestedCategoryRanges.single.start, DateTime(2026, 6, 1));

    await tester.tap(find.text('2026-06-01 – 2026-06-30'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(source.requestedTrendRanges.last.start, DateTime(2026, 6, 10));
    expect(source.requestedTrendRanges.last.end, DateTime(2026, 6, 20));
    expect(source.requestedCategoryRanges.last.start, DateTime(2026, 6, 10));
    expect(source.requestedCategoryRanges.last.end, DateTime(2026, 6, 20));
  });

  testWidgets('zero-filled trend buckets show the empty state', (tester) async {
    final source = _ReportingDataSource()
      ..trends = [
        OperationalTrendBucket(
          periodStart: DateTime(2026, 6, 1),
          depositAmount: 0,
          depositCount: 0,
          withdrawalAmount: 0,
          withdrawalCount: 0,
        ),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: OperationalTrendsWidget(dataSource: source)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada data'), findsOneWidget);
    expect(find.text('Nilai setoran dan pencairan (Rp)'), findsNothing);
  });

  testWidgets('trend chart exposes a numeric scale and exact value tooltip',
      (tester) async {
    final source = _ReportingDataSource()
      ..trends = [
        OperationalTrendBucket(
          periodStart: DateTime(2026, 6, 1),
          depositAmount: 1250,
          depositCount: 3,
          withdrawalAmount: 40,
          withdrawalCount: 1,
        ),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: OperationalTrendsWidget(dataSource: source)),
    ));
    await tester.pumpAndSettle();

    final amountChart = tester.widget<BarChart>(find.byType(BarChart).first);
    expect(
        amountChart.data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    final amountGroup = amountChart.data.barGroups.first;
    final tooltip =
        amountChart.data.barTouchData.touchTooltipData.getTooltipItem(
      amountGroup,
      0,
      amountGroup.barRods.first,
      0,
    );
    expect(tooltip!.text, contains('Setoran: Rp 1.250'));
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
