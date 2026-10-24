enum TrendGranularity { day, week, month }

class OperationalTrendBucket {
  final DateTime periodStart;
  final double depositAmount;
  final int depositCount;
  final double withdrawalAmount;
  final int withdrawalCount;

  const OperationalTrendBucket({
    required this.periodStart,
    required this.depositAmount,
    required this.depositCount,
    required this.withdrawalAmount,
    required this.withdrawalCount,
  });
}

class WasteCategoryTotal {
  final String category;
  final double totalWeightKg;
  final int depositCount;

  const WasteCategoryTotal({
    required this.category,
    required this.totalWeightKg,
    required this.depositCount,
  });
}

class DashboardReportRange {
  final DateTime start;
  final DateTime end;

  const DashboardReportRange({required this.start, required this.end});

  factory DashboardReportRange.currentMonth([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DashboardReportRange(
      start: DateTime(date.year, date.month),
      end: DateTime(date.year, date.month + 1, 0),
    );
  }
}

String reportDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
