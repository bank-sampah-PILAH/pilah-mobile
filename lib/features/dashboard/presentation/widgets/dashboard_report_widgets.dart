import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_range_filter.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_operational_chart.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';

export 'dashboard_report_range_filter.dart';

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
    this.color = AppColors.greenDark,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: AppTextStyle.small
                          .copyWith(color: AppColors.grey100)),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('$value${unit == null ? '' : ' $unit'}',
                style: AppTextStyle.headline1),
          ],
        ),
      );
}

class OperationalTrendsWidget extends StatefulWidget {
  final DashboardReportingDataSource dataSource;
  final DashboardReportRange? initialRange;
  final DashboardReportRange? range;

  const OperationalTrendsWidget({
    super.key,
    required this.dataSource,
    this.initialRange,
    this.range,
  });

  @override
  State<OperationalTrendsWidget> createState() =>
      _OperationalTrendsWidgetState();
}

class _OperationalTrendsWidgetState extends State<OperationalTrendsWidget> {
  late DashboardReportRange _range;
  late Future<List<OperationalTrendBucket>> _request;

  @override
  void initState() {
    super.initState();
    _range = widget.range ??
        widget.initialRange ??
        DashboardReportRange.currentMonth();
    _load();
  }

  @override
  void didUpdateWidget(covariant OperationalTrendsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.range != oldWidget.range && widget.range != null) {
      _range = widget.range!;
      _load();
    }
  }

  void _load() {
    _request = widget.dataSource.getOperationalTrends(
      range: widget.range ?? _range,
      granularity: TrendGranularity.day,
    );
  }

  void _update(DashboardReportRange range) {
    setState(() {
      _range = range;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) => _ReportCard(
        title: 'Tren operasional',
        controls: [
          if (widget.range == null)
            DashboardReportRangeFilter(range: _range, onChanged: _update),
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
            if (buckets.isEmpty ||
                buckets.every((bucket) =>
                    bucket.depositAmount == 0 &&
                    bucket.depositCount == 0 &&
                    bucket.withdrawalAmount == 0 &&
                    bucket.withdrawalCount == 0)) {
              return const _ReportMessage('Belum ada data');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardOperationalChart(buckets: buckets, isDeposit: true),
                const Divider(height: 40),
                DashboardOperationalChart(buckets: buckets, isDeposit: false),
              ],
            );
          },
        ),
      );
}

class WasteCategoriesWidget extends StatefulWidget {
  final DashboardReportingDataSource dataSource;
  final DashboardReportRange? initialRange;
  final DashboardReportRange? range;

  const WasteCategoriesWidget({
    super.key,
    required this.dataSource,
    this.initialRange,
    this.range,
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
    _range = widget.range ??
        widget.initialRange ??
        DashboardReportRange.currentMonth();
    _load();
  }

  @override
  void didUpdateWidget(covariant WasteCategoriesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.range != oldWidget.range && widget.range != null) {
      _range = widget.range!;
      _load();
    }
  }

  void _load() {
    _request = widget.dataSource.getWasteCategories(
      range: widget.range ?? _range,
    );
  }

  @override
  Widget build(BuildContext context) => _ReportCard(
        title: 'Kategori sampah',
        controls: [
          if (widget.range == null)
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
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.greenLight,
                          child:
                              Icon(Icons.recycling, color: AppColors.greenDark),
                        ),
                        title: Text(item.category,
                            style: AppTextStyle.small.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        subtitle: Text('${item.depositCount} setoran',
                            style: AppTextStyle.small.copyWith(
                              color: AppColors.grey100,
                            )),
                        trailing: Text(
                            '${WeightFormatter.formatKg(item.totalWeightKg)} kg',
                            style: AppTextStyle.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenDark,
                            )),
                      ))
                  .toList(),
            );
          },
        ),
      );
}

class DashboardReportsSection extends StatefulWidget {
  final DashboardReportingDataSource dataSource;
  final DashboardReportRange? initialRange;

  const DashboardReportsSection({
    super.key,
    required this.dataSource,
    this.initialRange,
  });

  @override
  State<DashboardReportsSection> createState() =>
      _DashboardReportsSectionState();
}

class _DashboardReportsSectionState extends State<DashboardReportsSection> {
  late DashboardReportRange _range;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange ?? DashboardReportRange.currentMonth();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Periode laporan', style: AppTextStyle.title1),
              DashboardReportRangeFilter(
                range: _range,
                onChanged: (value) => setState(() => _range = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OperationalTrendsWidget(
            dataSource: widget.dataSource,
            range: _range,
          ),
          const SizedBox(height: 24),
          WasteCategoriesWidget(
            dataSource: widget.dataSource,
            range: _range,
          ),
        ],
      );
}

class _ReportCard extends StatelessWidget {
  final String title;
  final List<Widget> controls;
  final Widget child;

  const _ReportCard(
      {required this.title, required this.controls, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: AppTextStyle.title1),
                ...controls,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      );
}

class _ReportMessage extends StatelessWidget {
  final String message;
  const _ReportMessage(this.message);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(message,
              style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
        ),
      );
}
