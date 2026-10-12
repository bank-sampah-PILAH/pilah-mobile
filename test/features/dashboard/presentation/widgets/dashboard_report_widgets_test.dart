import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';

class _ReportingDataSource implements DashboardReportingDataSource {
  List<OperationalTrendBucket> trends = const [];
  List<WasteCategoryTotal> categories = const [];
  Object? trendError;
  Object? categoryError;
  final requestedTrendRanges = <DashboardReportRange>[];
  final requestedTrendGranularities = <TrendGranularity>[];
  final requestedCategoryRanges = <DashboardReportRange>[];

  @override
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  }) async {
    requestedTrendRanges.add(range);
    requestedTrendGranularities.add(granularity);
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
  testWidgets('report cards use PILAH styles and fit a full month on mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _ReportingDataSource()
      ..trends = List.generate(
        31,
        (index) => OperationalTrendBucket(
          periodStart: DateTime(2026, 10, index + 1),
          depositAmount: 100,
          depositCount: 1,
          withdrawalAmount: 50,
          withdrawalCount: 1,
        ),
      );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OperationalTrendsWidget(dataSource: source),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Tren operasional'));
    expect(title.style!.fontFamily, AppTextStyle.title1.fontFamily);
    final chart = tester.widget<BarChart>(find.byType(BarChart).first);
    expect(
        chart.data.barGroups.first.barRods.single.color, AppColors.statPurple);
    final line = tester.widget<LineChart>(find.byType(LineChart).first);
    expect(line.data.lineBarsData.single.color, AppColors.greenDark);
    final occupiedWidth = chart.data.barGroups.fold<double>(
        0,
        (total, group) =>
            total +
            group.barRods.fold<double>(0, (width, rod) => width + rod.width) +
            group.barsSpace);
    expect(occupiedWidth,
        lessThan(tester.getSize(find.byType(BarChart).first).width - 116));
    expect(find.text('10-02'), findsNothing);
    expect(find.text('10-01'), findsNWidgets(2));
    expect(find.text('10-31'), findsNWidgets(2));
    final dateLabels = find.descendant(
        of: find.byType(BarChart).first,
        matching: find.byWidgetPredicate((widget) =>
            widget is Text &&
            RegExp(r'^\d{2}-\d{2}$').hasMatch(widget.data ?? '')));
    final bounds = [
      for (final element in dateLabels.evaluate())
        tester.getRect(find.byWidget(element.widget))
    ]..sort((a, b) => a.left.compareTo(b.left));
    for (var i = 1; i < bounds.length; i++) {
      expect(bounds[i].left - bounds[i - 1].right, greaterThanOrEqualTo(4));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports fit a narrow viewport without clipping controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _ReportingDataSource()
      ..categories = const [
        WasteCategoryTotal(
            category: 'Plastik', totalWeightKg: 2, depositCount: 1),
      ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardReportsSection(dataSource: source),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Periode laporan'), findsOneWidget);
    expect(find.text('2 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Setoran and Pencairan combine counts and Rupiah on separate axes',
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
      home: Scaffold(
          body: SingleChildScrollView(
              child: OperationalTrendsWidget(dataSource: source))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('Transaksi'), findsNWidgets(2));
    expect(find.text('Rupiah (Rp)'), findsNWidgets(2));
    expect(find.byType(BarChart), findsNWidgets(2));
    expect(find.byType(LineChart), findsNWidgets(2));
    expect(find.byType(DropdownButton<TrendGranularity>), findsNothing);
  });

  testWidgets('report section defaults both widgets to the current month',
      (tester) async {
    final source = _ReportingDataSource();
    final expectedRange = DashboardReportRange.currentMonth(DateTime.now());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardReportsSection(dataSource: source),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(source.requestedTrendRanges.single.start, expectedRange.start);
    expect(source.requestedTrendRanges.single.end, expectedRange.end);
    expect(source.requestedCategoryRanges.single.start, expectedRange.start);
    expect(source.requestedCategoryRanges.single.end, expectedRange.end);
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

    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-20')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
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
    expect(find.byType(LineChart), findsNothing);
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
      home: Scaffold(
          body: SingleChildScrollView(
              child: OperationalTrendsWidget(dataSource: source))),
    ));
    await tester.pumpAndSettle();

    final deposit = tester.widget<BarChart>(find.byType(BarChart).first).data;
    expect(deposit.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    expect(deposit.titlesData.rightTitles.sideTitles.showTitles, isTrue);
    expect(deposit.titlesData.leftTitles.sideTitles.interval,
        greaterThanOrEqualTo(1));
    expect(deposit.barGroups.single.barRods.single.toY, 3);
    final line = tester.widget<LineChart>(find.byType(LineChart).first).data;
    final series = line.lineBarsData.single;
    final tooltip = line.lineTouchData.touchTooltipData.getTooltipItems([
      LineBarSpot(series, 0, series.spots.single),
    ]).single!;
    expect(tooltip.text, contains('Setoran: 3 transaksi'));
    expect(tooltip.text, contains('Rp 1.250'));
    expect(line.minX, -0.5);
    expect(line.maxX, 0.5);
    expect(line.maxY, deposit.maxY);
    expect(line.lineBarsData.single.spots.single.y,
        closeTo(1250 / (1250 * 1.15) * deposit.maxY, 0.00001));
    expect(line.lineBarsData.single.isCurved, isTrue);
    expect(line.lineBarsData.single.preventCurveOverShooting, isTrue);

    final withdrawal =
        tester.widget<LineChart>(find.byType(LineChart).last).data;
    final withdrawalSeries = withdrawal.lineBarsData.single;
    final withdrawalTooltip =
        withdrawal.lineTouchData.touchTooltipData.getTooltipItems([
      LineBarSpot(withdrawalSeries, 0, withdrawalSeries.spots.single),
    ]).single!;
    expect(withdrawalTooltip.text, contains('Pencairan: 1 transaksi'));
    expect(withdrawalTooltip.text, contains('Rp 40'));
  });

  testWidgets('empty and failed reports have independent feedback',
      (tester) async {
    final source = _ReportingDataSource()..categoryError = Exception('offline');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Expanded(
              child: SingleChildScrollView(
                  child: OperationalTrendsWidget(dataSource: source))),
          Expanded(
              child: SingleChildScrollView(
                  child: WasteCategoriesWidget(dataSource: source))),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada data'), findsOneWidget);
    expect(find.text('Gagal memuat kategori'), findsOneWidget);
  });

  testWidgets('KPI cards display values with and without units',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            DashboardKpiCard(
              label: 'Transaksi',
              value: '7',
              icon: Icons.show_chart,
            ),
            DashboardKpiCard(
              label: 'Berat',
              value: '2',
              unit: 'kg',
              icon: Icons.scale,
            ),
          ],
        ),
      ),
    ));

    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Berat'), findsOneWidget);
    expect(find.text('2 kg'), findsOneWidget);
  });

  testWidgets('standalone trend controls update range with daily buckets',
      (tester) async {
    final source = _ReportingDataSource()
      ..trends = [
        OperationalTrendBucket(
          periodStart: DateTime(2026, 6, 1),
          depositAmount: 10,
          depositCount: 1,
          withdrawalAmount: 5,
          withdrawalCount: 1,
        ),
      ];
    final initialRange = DashboardReportRange(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 30),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OperationalTrendsWidget(
            dataSource: source,
            initialRange: initialRange,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(source.requestedTrendGranularities.single, TrendGranularity.day);

    expect(find.byType(DropdownButton<TrendGranularity>), findsNothing);

    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-20')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(source.requestedTrendRanges.last.start, DateTime(2026, 6, 10));
    expect(source.requestedTrendRanges.last.end, DateTime(2026, 6, 20));
    expect(source.requestedTrendGranularities.last, TrendGranularity.day);
  });

  testWidgets('standalone category filter updates its request range',
      (tester) async {
    final source = _ReportingDataSource()
      ..categories = const [
        WasteCategoryTotal(
          category: 'Plastik',
          totalWeightKg: 2,
          depositCount: 1,
        ),
      ];
    final initialRange = DashboardReportRange(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 30),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WasteCategoriesWidget(
          dataSource: source,
          initialRange: initialRange,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-date-2026-06-20')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(source.requestedCategoryRanges.last.start, DateTime(2026, 6, 10));
    expect(source.requestedCategoryRanges.last.end, DateTime(2026, 6, 20));
  });
}
