import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
  Widget build(BuildContext context) => FutureBuilder<List<WasteCategoryTotal>>(
        future: _request,
        builder: (context, snapshot) {
          final categories =
              snapshot.hasData ? [...snapshot.data!] : <WasteCategoryTotal>[];
          categories.sort((a, b) => b.totalWeightKg.compareTo(a.totalWeightKg));
          final totalWeightKg = categories.fold<double>(
              0, (total, category) => total + category.totalWeightKg);
          final hasData = snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              categories.isNotEmpty &&
              totalWeightKg > 0;

          return _ReportCard(
            title: 'Kategori sampah',
            subtitle: reportCategoryWeightSubtitle(widget.range ?? _range),
            trailing: hasData
                ? _ReportTotalBadge(totalWeightKg: totalWeightKg)
                : null,
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
            child: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? const _ReportMessage('Gagal memuat kategori')
                    : !hasData
                        ? const _ReportMessage('Belum ada data')
                        : _WasteCategoryBreakdown(
                            categories: categories,
                            totalWeightKg: totalWeightKg,
                          ),
          );
        },
      );
}

final _categoryChartColors = <Color>[
  AppColors.greenDark,
  AppColors.statOrange,
  AppColors.statPurple,
  AppColors.avatarFills[3],
  AppColors.inkSoft,
  AppColors.avatarFills[4],
  AppColors.grey100,
];

class _ReportTotalBadge extends StatelessWidget {
  final double totalWeightKg;

  const _ReportTotalBadge({required this.totalWeightKg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Total ${WeightFormatter.formatKg(totalWeightKg)} kg',
          style: AppTextStyle.small.copyWith(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _WasteCategoryBreakdown extends StatelessWidget {
  final List<WasteCategoryTotal> categories;
  final double totalWeightKg;

  const _WasteCategoryBreakdown({
    required this.categories,
    required this.totalWeightKg,
  });

  String _percentage(double weight) =>
      '${(weight / totalWeightKg * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final chart = _donut();
          final ranking = Column(
            children: categories.indexed
                .map((entry) => _categoryRow(entry.$1, entry.$2, isWide))
                .toList(),
          );
          final others =
              categories.skip(1).take(2).map((item) => item.category);
          final followedBy = others.isEmpty
              ? ''
              : ', diikuti ${others.length == 1 ? others.first : '${others.first} dan ${others.last}'}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 220, child: chart),
                    const SizedBox(width: 24),
                    Expanded(child: ranking),
                  ],
                )
              else ...[
                Center(child: chart),
                const SizedBox(height: 16),
                ranking,
              ],
              const SizedBox(height: 16),
              Text(
                '${categories.first.category} menyumbang ${_percentage(categories.first.totalWeightKg)} dari total berat periode ini$followedBy.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            ],
          );
        },
      );

  Widget _donut() {
    final sections = categories.indexed.map((entry) {
      final color =
          _categoryChartColors[entry.$1 % _categoryChartColors.length];
      return PieChartSectionData(
        value: entry.$2.totalWeightKg,
        color: color,
        radius: 42,
        showTitle: false,
        borderSide: const BorderSide(color: Colors.white, width: 2),
      );
    }).toList();
    final categorySummary = categories.indexed
        .map((entry) => '${entry.$1 + 1}. ${entry.$2.category}: '
            '${WeightFormatter.formatKg(entry.$2.totalWeightKg)} kg, '
            '${_percentage(entry.$2.totalWeightKg)}')
        .join('; ');

    return Semantics(
      label:
          'Total ${WeightFormatter.formatKg(totalWeightKg)} kg. $categorySummary',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 58,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(enabled: false),
                ),
                duration: Duration.zero,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(WeightFormatter.formatKg(totalWeightKg),
                      style: AppTextStyle.headline1),
                  Text('kg total',
                      style: AppTextStyle.small
                          .copyWith(color: AppColors.grey100)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(int index, WasteCategoryTotal category, bool isWide) {
    final color = _categoryChartColors[index % _categoryChartColors.length];
    final weight = '${WeightFormatter.formatKg(category.totalWeightKg)} kg';
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LinearProgressIndicator(
        value: (category.totalWeightKg / categories.first.totalWeightKg)
            .clamp(0.0, 1.0)
            .toDouble(),
        minHeight: 8,
        color: color,
        backgroundColor: AppColors.fill,
      ),
    );
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600)),
        Text('${category.depositCount} setoran',
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100)),
      ],
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            SizedBox(
                width: 18,
                child: Text('${index + 1}', style: AppTextStyle.small)),
            const SizedBox(width: 12),
            SizedBox(width: 100, child: name),
            const SizedBox(width: 16),
            Expanded(child: bar),
            const SizedBox(width: 16),
            SizedBox(
                width: 68,
                child: Text(weight,
                    textAlign: TextAlign.right, style: AppTextStyle.small)),
            const SizedBox(width: 12),
            SizedBox(
                width: 46,
                child: Text(_percentage(category.totalWeightKg),
                    textAlign: TextAlign.right,
                    style: AppTextStyle.extraSmall)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 18,
                  child: Text('${index + 1}', style: AppTextStyle.small)),
              const SizedBox(width: 8),
              Expanded(child: name),
              const SizedBox(width: 8),
              SizedBox(
                  width: 64,
                  child: Text(weight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyle.small)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 46,
                  child: Text(_percentage(category.totalWeightKg),
                      textAlign: TextAlign.right,
                      style: AppTextStyle.extraSmall)),
            ],
          ),
          const SizedBox(height: 8),
          bar,
        ],
      ),
    );
  }
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
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> controls;
  final Widget child;

  const _ReportCard({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.controls,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle == null && trailing == null)
              Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: AppTextStyle.title1),
                  ...controls,
                ],
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyle.title1),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              style: AppTextStyle.small
                                  .copyWith(color: AppColors.grey100)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              if (controls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 24, runSpacing: 12, children: controls),
              ],
            ],
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
