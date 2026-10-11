import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
    this.color = const Color(0xFF16865B),
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text('$value${unit == null ? '' : ' $unit'}',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}

class DashboardReportRangeFilter extends StatelessWidget {
  final DashboardReportRange range;
  final ValueChanged<DashboardReportRange> onChanged;

  const DashboardReportRangeFilter({
    super.key,
    required this.range,
    required this.onChanged,
  });

  Future<void> _select(BuildContext context) async {
    final today = DateTime.now();
    final lastDate = range.end.isAfter(today) ? range.end : today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );
    if (picked != null) {
      onChanged(DashboardReportRange(start: picked.start, end: picked.end));
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => _select(context),
        icon: const Icon(Icons.calendar_month),
        label: Text('${reportDate(range.start)} – ${reportDate(range.end)}'),
      );
}

class OperationalTrendsWidget extends StatefulWidget {
  final DashboardReportingDataSource dataSource;
  final DashboardReportRange? initialRange;

  const OperationalTrendsWidget({
    super.key,
    required this.dataSource,
    this.initialRange,
  });

  @override
  State<OperationalTrendsWidget> createState() =>
      _OperationalTrendsWidgetState();
}

class _OperationalTrendsWidgetState extends State<OperationalTrendsWidget> {
  late DashboardReportRange _range;
  TrendGranularity _granularity = TrendGranularity.day;
  late Future<List<OperationalTrendBucket>> _request;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange ?? DashboardReportRange.currentMonth();
    _load();
  }

  void _load() {
    _request = widget.dataSource.getOperationalTrends(
      range: _range,
      granularity: _granularity,
    );
  }

  void _update({DashboardReportRange? range, TrendGranularity? granularity}) {
    setState(() {
      _range = range ?? _range;
      _granularity = granularity ?? _granularity;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) => _ReportCard(
        title: 'Tren operasional',
        controls: [
          DashboardReportRangeFilter(
              range: _range, onChanged: (v) => _update(range: v)),
          DropdownButton<TrendGranularity>(
            value: _granularity,
            onChanged: (value) {
              if (value != null) _update(granularity: value);
            },
            items: TrendGranularity.values
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(switch (value) {
                        TrendGranularity.day => 'Hari',
                        TrendGranularity.week => 'Minggu',
                        TrendGranularity.month => 'Bulan',
                      }),
                    ))
                .toList(),
          ),
        ],
        child: FutureBuilder<List<OperationalTrendBucket>>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _ReportMessage('Gagal memuat tren');
            }
            final buckets = snapshot.data ?? const [];
            if (buckets.isEmpty) return const _ReportMessage('Belum ada data');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrendChart(
                  title: 'Nilai setoran dan pencairan (Rp)',
                  labels:
                      buckets.map((b) => reportDate(b.periodStart)).toList(),
                  values: buckets
                      .map((b) => (b.depositAmount, b.withdrawalAmount))
                      .toList(),
                ),
                const SizedBox(height: 16),
                _TrendChart(
                  title: 'Jumlah setoran dan pencairan (transaksi)',
                  labels:
                      buckets.map((b) => reportDate(b.periodStart)).toList(),
                  values: buckets
                      .map((b) => (
                            b.depositCount.toDouble(),
                            b.withdrawalCount.toDouble()
                          ))
                      .toList(),
                ),
                const Row(children: [
                  _Legend(color: Color(0xFF16865B), label: 'Setoran'),
                  SizedBox(width: 16),
                  _Legend(color: Color(0xFFE98B35), label: 'Pencairan'),
                ]),
              ],
            );
          },
        ),
      );
}

class WasteCategoriesWidget extends StatefulWidget {
  final DashboardReportingDataSource dataSource;
  final DashboardReportRange? initialRange;

  const WasteCategoriesWidget({
    super.key,
    required this.dataSource,
    this.initialRange,
  });

  @override
  State<WasteCategoriesWidget> createState() => _WasteCategoriesWidgetState();
}

class _WasteCategoriesWidgetState extends State<WasteCategoriesWidget> {
  late DashboardReportRange _range;
  late Future<List<WasteCategoryTotal>> _request;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange ?? DashboardReportRange.currentMonth();
    _load();
  }

  void _load() {
    _request = widget.dataSource.getWasteCategories(range: _range);
  }

  @override
  Widget build(BuildContext context) => _ReportCard(
        title: 'Kategori sampah',
        controls: [
          DashboardReportRangeFilter(
            range: _range,
            onChanged: (value) => setState(() {
              _range = value;
              _load();
            }),
          ),
        ],
        child: FutureBuilder<List<WasteCategoryTotal>>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _ReportMessage('Gagal memuat kategori');
            }
            final categories = [
              ...snapshot.data ?? const <WasteCategoryTotal>[]
            ]..sort((a, b) => b.totalWeightKg.compareTo(a.totalWeightKg));
            if (categories.isEmpty) {
              return const _ReportMessage('Belum ada data');
            }
            return Column(
              children: categories
                  .map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.category),
                        subtitle: Text('${item.depositCount} setoran'),
                        trailing: Text('${_number(item.totalWeightKg)} kg'),
                      ))
                  .toList(),
            );
          },
        ),
      );
}

class _ReportCard extends StatelessWidget {
  final String title;
  final List<Widget> controls;
  final Widget child;

  const _ReportCard(
      {required this.title, required this.controls, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 8, runSpacing: 4, children: controls),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );
}

class _TrendChart extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<(double, double)> values;

  const _TrendChart({
    required this.title,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              barGroups: values.indexed
                  .map((entry) => BarChartGroupData(
                        x: entry.$1,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                              toY: entry.$2.$1,
                              color: const Color(0xFF16865B),
                              width: 8),
                          BarChartRodData(
                              toY: entry.$2.$2,
                              color: const Color(0xFFE98B35),
                              width: 8),
                        ],
                      ))
                  .toList(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (labels.length / 5)
                        .ceilToDouble()
                        .clamp(1, double.infinity),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          labels[index].substring(5),
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            )),
          ),
        ],
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label),
      ]);
}

class _ReportMessage extends StatelessWidget {
  final String message;
  const _ReportMessage(this.message);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      );
}

String _number(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
