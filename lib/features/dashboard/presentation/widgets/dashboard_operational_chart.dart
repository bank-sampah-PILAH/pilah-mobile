import 'dart:math' as math;
// CI benchmark scratch: documentation comment only, no behavior change.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

class DashboardOperationalChart extends StatelessWidget {
  final List<OperationalTrendBucket> buckets;
  final bool isDeposit;

  const DashboardOperationalChart(
      {super.key, required this.buckets, required this.isDeposit});

  String get _title => isDeposit ? 'Setoran' : 'Pencairan';

  @override
  Widget build(BuildContext context) {
    final values = buckets
        .map((bucket) => isDeposit
            ? (bucket.depositCount, bucket.depositAmount)
            : (bucket.withdrawalCount, bucket.withdrawalAmount))
        .toList();
    final countMax = math.max(
        1.0,
        (values.fold<double>(
                    0,
                    (highest, value) =>
                        math.max(highest, value.$1.toDouble())) *
                1.15)
            .ceilToDouble());
    final amountMax = math.max(
        1.0,
        values.fold<double>(
                0, (highest, value) => math.max(highest, value.$2)) *
            1.15);
    final interval = (countMax / 4).ceilToDouble();
    final datePainter = TextPainter(
      text: TextSpan(text: '00-00', style: AppTextStyle.extraSmall),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final dateGap = datePainter.width + 12;
    datePainter.dispose();
    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
          sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: interval,
        getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child:
                Text(value.toStringAsFixed(0), style: AppTextStyle.extraSmall)),
      )),
      rightTitles: AxisTitles(
          sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 76,
        interval: interval,
        getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_amountLabel(value / countMax * amountMax),
                style: AppTextStyle.extraSmall)),
      )),
      bottomTitles: AxisTitles(
          sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (value, meta) => _dateTitle(value, meta, dateGap),
      )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_title, style: AppTextStyle.title1),
              _legend(AppColors.statPurple, 'Jumlah transaksi', false),
              _legend(AppColors.greenDark, 'Nilai (Rp)', true),
            ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Transaksi', style: AppTextStyle.extraSmall),
          Text('Rupiah (Rp)', style: AppTextStyle.extraSmall),
        ]),
        const SizedBox(height: 8),
        Semantics(
          label:
              '$_title. Batang: jumlah transaksi. Garis: nilai Rupiah. ${values.indexed.map((entry) => '${reportDate(buckets[entry.$1].periodStart)}: ${entry.$2.$1} transaksi, ${_rupiah(entry.$2.$2)}').join('; ')}',
          excludeSemantics: true,
          child: SizedBox(
            height: 240,
            child: LayoutBuilder(builder: (context, constraints) {
              final slotWidth =
                  (constraints.maxWidth - 116) / math.max(1, values.length);
              final barWidth = (slotWidth * 0.6).clamp(1.0, 32.0);
              final bars = BarChartData(
                minY: 0,
                maxY: countMax,
                alignment: BarChartAlignment.spaceAround,
                titlesData: titles,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.grey200.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: values.indexed
                    .map((entry) => BarChartGroupData(
                          x: entry.$1,
                          barRods: [
                            BarChartRodData(
                              toY: entry.$2.$1.toDouble(),
                              width: barWidth,
                              color: AppColors.statPurple,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            )
                          ],
                        ))
                    .toList(),
                barTouchData: BarTouchData(enabled: false),
              );
              // Normalize line coordinates only; the right axis and tooltip retain Rupiah.
              final line = LineChartData(
                minX: -0.5,
                maxX: math.max(1, values.length) - 0.5,
                minY: 0,
                maxY: countMax,
                titlesData: _blankTitles(titles),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                lineTouchData: LineTouchData(
                  touchSpotThreshold: slotWidth / 2 + 1,
                  getTouchedSpotIndicator: (bar, indexes) => indexes
                      .map((index) => const TouchedSpotIndicatorData(
                            FlLine(
                                color: AppColors.grey200,
                                strokeWidth: 1,
                                dashArray: [4, 4]),
                            FlDotData(),
                          ))
                      .toList(),
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: math.min(
                        220.0, math.max(100.0, constraints.maxWidth - 148)),
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.spotIndex;
                      return LineTooltipItem(
                        '${reportDate(buckets[index].periodStart)}\n$_title: ${values[index].$1} transaksi\n${_rupiah(values[index].$2)}',
                        AppTextStyle.small.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: values.indexed
                        .map((entry) => FlSpot(
                              entry.$1.toDouble(),
                              entry.$2.$2 / amountMax * countMax,
                            ))
                        .toList(),
                    color: AppColors.greenDark,
                    barWidth: 3,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    preventCurveOverShooting: true,
                    preventCurveOvershootingThreshold: 0,
                    dotData: FlDotData(show: values.length == 1),
                  )
                ],
              );
              return Stack(children: [
                BarChart(bars, duration: Duration.zero),
                LineChart(line, duration: Duration.zero),
              ]);
            }),
          ),
        ),
      ],
    );
  }

  Widget _dateTitle(double value, TitleMeta meta, double minimumGap) {
    final index = value.toInt();
    final slots =
        math.max(1, math.min(5, (meta.parentAxisSize / minimumGap).floor()));
    final step = math.max(1, (buckets.length / slots).ceil());
    final last = buckets.length - 1;
    if (index < 0 || index > last) return const SizedBox.shrink();
    if (index != last &&
        (index % step != 0 ||
            (last - index) * meta.parentAxisSize / buckets.length <
                minimumGap)) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
        meta: meta,
        child: Text(
          reportDate(buckets[index].periodStart).substring(5),
          style: AppTextStyle.extraSmall,
        ));
  }

  FlTitlesData _blankTitles(FlTitlesData titles) => titles.copyWith(
        leftTitles: titles.leftTitles.copyWith(
            sideTitles: titles.leftTitles.sideTitles
                .copyWith(getTitlesWidget: _blankTitle)),
        rightTitles: titles.rightTitles.copyWith(
            sideTitles: titles.rightTitles.sideTitles
                .copyWith(getTitlesWidget: _blankTitle)),
        bottomTitles: titles.bottomTitles.copyWith(
            sideTitles: titles.bottomTitles.sideTitles
                .copyWith(getTitlesWidget: _blankTitle)),
      );

  Widget _blankTitle(double value, TitleMeta meta) => const SizedBox.shrink();

  Widget _legend(Color color, String label, bool line) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 16,
              height: line ? 3 : 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyle.small),
        ],
      );
}

String _rupiah(double value) {
  final cents = (value * 100).round();
  final fraction = cents % 100;
  return '${CurrencyFormatter.formatRupiah(cents ~/ 100)}${fraction == 0 ? '' : ',${fraction.toString().padLeft(2, '0')}'}';
}

String _amountLabel(double value) {
  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
  }
  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(1)} rb';
  }
  return _rupiah(value);
}
