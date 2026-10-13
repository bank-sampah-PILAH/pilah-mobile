import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_operational_chart.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<OperationalTrendBucket> buckets,
          {bool isDeposit = true}) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20),
                child: DashboardOperationalChart(
                    buckets: buckets, isDeposit: isDeposit))),
      ));

  testWidgets('bar and line layers align and keep independent scales',
      (tester) async {
    final buckets = List.generate(
        3,
        (index) => OperationalTrendBucket(
              periodStart: DateTime(2026, 6, index + 1),
              depositCount: [2, 5, 0][index],
              depositAmount: [2000000.0, 500.0, 0.0][index],
              withdrawalCount: 0,
              withdrawalAmount: 0,
            ));
    await pump(tester, buckets);
    await tester.pumpAndSettle();
    final bars = tester.widget<BarChart>(find.byType(BarChart)).data;
    final line = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(bars.alignment, BarChartAlignment.spaceAround);
    expect(line.minX, -0.5);
    expect(line.maxX, 2.5);
    expect(tester.getRect(find.byType(LineChart)),
        tester.getRect(find.byType(BarChart)));
    for (final index in [0, 1, 2]) {
      expect(bars.barGroups[index].barRods.single.toY,
          buckets[index].depositCount.toDouble());
      expect(line.lineBarsData.single.spots[index].x, index.toDouble());
      expect(
          line.lineBarsData.single.spots[index].y,
          closeTo(
              buckets[index].depositAmount / 2300000 * bars.maxY, 0.000001));
    }
    expect(line.titlesData.leftTitles.sideTitles.reservedSize,
        bars.titlesData.leftTitles.sideTitles.reservedSize);
    expect(line.titlesData.rightTitles.sideTitles.reservedSize,
        bars.titlesData.rightTitles.sideTitles.reservedSize);
    expect(line.titlesData.bottomTitles.sideTitles.reservedSize,
        bars.titlesData.bottomTitles.sideTitles.reservedSize);
    expect(bars.titlesData.leftTitles.sideTitles.interval! % 1, 0);
    expect(bars.barTouchData.enabled, isFalse);
    expect(line.lineTouchData.enabled, isTrue);
    final indicator = line.lineTouchData
        .getTouchedSpotIndicator(line.lineBarsData.single, [0]).single!;
    expect(indicator.indicatorBelowLine.strokeWidth, 1);
    expect(indicator.touchedSpotDotData.show, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltips preserve fractional Rupiah for both operations',
      (tester) async {
    final bucket = OperationalTrendBucket(
        periodStart: DateTime(2026, 6),
        depositCount: 2,
        depositAmount: 1234.56,
        withdrawalCount: 1,
        withdrawalAmount: 10.01);
    for (final deposit in [true, false]) {
      await pump(tester, [bucket], isDeposit: deposit);
      await tester.pumpAndSettle();
      final line = tester.widget<LineChart>(find.byType(LineChart)).data;
      final series = line.lineBarsData.single;
      final tooltip = line.lineTouchData.touchTooltipData.getTooltipItems([
        LineBarSpot(series, 0, series.spots.single),
      ]).single!;
      expect(
          tooltip.text,
          contains(
              deposit ? 'Setoran: 2 transaksi' : 'Pencairan: 1 transaksi'));
      expect(tooltip.text, contains(deposit ? 'Rp 1.234,56' : 'Rp 10,01'));
    }
  });

  testWidgets('zero-valued operation keeps valid axes and a zero tooltip',
      (tester) async {
    await pump(tester, [
      OperationalTrendBucket(
          periodStart: DateTime(2026, 6),
          depositCount: 0,
          depositAmount: 0,
          withdrawalCount: 0,
          withdrawalAmount: 0)
    ]);
    await tester.pumpAndSettle();
    final bars = tester.widget<BarChart>(find.byType(BarChart)).data;
    final line = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(bars.maxY, 1);
    expect(line.lineBarsData.single.spots.single.y, 0);
    final series = line.lineBarsData.single;
    expect(
        line.lineTouchData.touchTooltipData
            .getTooltipItems([
              LineBarSpot(series, 0, series.spots.single),
            ])
            .single!
            .text,
        contains('0 transaksi\nRp 0'));
    expect(tester.takeException(), isNull);
  });
}
