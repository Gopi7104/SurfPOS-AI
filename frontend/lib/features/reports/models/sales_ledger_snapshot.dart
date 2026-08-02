import 'report_period.dart';
import 'sales_record.dart';

/// One point on a trend chart — a plain, model-agnostic value so both
/// Dashboard's `DemoTrendPoint`-typed sections and Reports' own
/// `SalesTrendPoint` can each build their own typed object from it with a
/// one-line map, without this file depending on either.
typedef LedgerTrendPoint = ({String label, double amount});

/// One payment-method slice — same model-agnostic shape as
/// [LedgerTrendPoint], for the same reason.
typedef LedgerPaymentSlice = ({
  String method,
  double amount,
  double percentage
});

/// Real, on-device business figures derived entirely from
/// [SalesRecord]s — the real counterpart to `DemoBusinessSnapshot`, used
/// by both Dashboard (today's figures) and Reports (period-filtered
/// figures) once at least one real sale has been recorded. Every "today"/
/// "this week"/"this month" window is anchored on the real [now] (unlike
/// `DemoBusinessSnapshot`, which anchors on its most recent generated
/// sale) — real sales genuinely happened at real times.
class SalesLedgerSnapshot {
  SalesLedgerSnapshot(this.records, {DateTime? now})
      : now = now ?? DateTime.now();

  final List<SalesRecord> records;
  final DateTime now;

  bool get isEmpty => records.isEmpty;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime get _today => _dateOnly(now);
  DateTime get _yesterday => _today.subtract(const Duration(days: 1));
  DateTime get _thisWeekStart =>
      _today.subtract(Duration(days: _today.weekday - 1));
  DateTime get _thisMonthStart => DateTime(_today.year, _today.month, 1);

  double _sumInRange(DateTime startInclusive, DateTime endExclusive) {
    return records
        .where((r) =>
            !r.occurredAt.isBefore(startInclusive) &&
            r.occurredAt.isBefore(endExclusive))
        .fold(0.0, (sum, r) => sum + r.total);
  }

  int _countInRange(DateTime startInclusive, DateTime endExclusive) {
    return records
        .where((r) =>
            !r.occurredAt.isBefore(startInclusive) &&
            r.occurredAt.isBefore(endExclusive))
        .length;
  }

  List<SalesRecord> _recordsInRange(
      DateTime startInclusive, DateTime endExclusive) {
    return records
        .where((r) =>
            !r.occurredAt.isBefore(startInclusive) &&
            r.occurredAt.isBefore(endExclusive))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Core KPIs
  // ---------------------------------------------------------------------

  double get todaySales =>
      _sumInRange(_today, _today.add(const Duration(days: 1)));
  double get yesterdaySales => _sumInRange(_yesterday, _today);
  double? get todaySalesGrowth => yesterdaySales == 0
      ? null
      : (todaySales - yesterdaySales) / yesterdaySales * 100;

  int get todayOrders =>
      _countInRange(_today, _today.add(const Duration(days: 1)));

  double get thisWeekSales =>
      _sumInRange(_thisWeekStart, _thisWeekStart.add(const Duration(days: 7)));
  double get _lastWeekSales => _sumInRange(
      _thisWeekStart.subtract(const Duration(days: 7)), _thisWeekStart);
  double? get thisWeekGrowth => _lastWeekSales == 0
      ? null
      : (thisWeekSales - _lastWeekSales) / _lastWeekSales * 100;

  double get thisMonthSales =>
      _sumInRange(_thisMonthStart, DateTime(_today.year, _today.month + 1, 1));
  double get _lastMonthSales =>
      _sumInRange(DateTime(_today.year, _today.month - 1, 1), _thisMonthStart);
  double? get thisMonthGrowth => _lastMonthSales == 0
      ? null
      : (thisMonthSales - _lastMonthSales) / _lastMonthSales * 100;

  double get totalRevenue => records.fold(0.0, (sum, r) => sum + r.total);
  int get totalOrders => records.length;
  double get averageOrderValue =>
      totalOrders == 0 ? 0 : totalRevenue / totalOrders;
  double get todayAverageOrderValue =>
      todayOrders == 0 ? 0 : todaySales / todayOrders;

  // ---------------------------------------------------------------------
  // Trend charts
  // ---------------------------------------------------------------------

  String _hourLabel(int hour) {
    final period = hour < 12 ? 'am' : 'pm';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h$period';
  }

  String _dayLabel(DateTime day) => '${day.day}/${day.month}';

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  List<LedgerTrendPoint> _hourlyBuckets(DateTime dayStart) {
    return [
      for (var hour = 0; hour < 24; hour += 4)
        (
          label: _hourLabel(hour),
          amount: _sumInRange(
            dayStart.add(Duration(hours: hour)),
            dayStart.add(Duration(hours: hour + 4)),
          ),
        ),
    ];
  }

  List<LedgerTrendPoint> _dailyBuckets(DateTime start, int days) {
    return [
      for (var i = 0; i < days; i++)
        (
          label: _dayLabel(start.add(Duration(days: i))),
          amount: _sumInRange(
            start.add(Duration(days: i)),
            start.add(Duration(days: i + 1)),
          ),
        ),
    ];
  }

  /// The last 14 calendar days, always at daily granularity — mirrors
  /// `DemoBusinessSnapshot.salesTrend`'s own fixed window (Dashboard's
  /// Sales Trend section never depends on any period toggle).
  List<LedgerTrendPoint> get salesTrend14Days =>
      _dailyBuckets(_today.subtract(const Duration(days: 13)), 14);

  /// Dashboard's Revenue Chart Today/Week/Month toggle — same bucketing
  /// `DemoBusinessSnapshot.revenueTrend` uses, just anchored on real "now".
  List<LedgerTrendPoint> revenueTrendToday() => _hourlyBuckets(_today);

  List<LedgerTrendPoint> revenueTrendThisWeek() {
    return [
      for (var i = 0; i < 7; i++)
        (
          label: _weekdayLabels[i],
          amount: _sumInRange(
            _thisWeekStart.add(Duration(days: i)),
            _thisWeekStart.add(Duration(days: i + 1)),
          ),
        ),
    ];
  }

  List<LedgerTrendPoint> revenueTrendThisMonth() {
    final daysInMonth = DateTime(_today.year, _today.month + 1, 0).day;
    final weeks = (daysInMonth / 7).ceil();
    return [
      for (var week = 0; week < weeks; week++)
        (
          label: 'Week ${week + 1}',
          amount: _sumInRange(
            _thisMonthStart.add(Duration(days: week * 7)),
            _thisMonthStart
                .add(Duration(days: daysInMonth.clamp(0, (week + 1) * 7))),
          ),
        ),
    ];
  }

  /// Reports' period-filtered figures/sections — [period]/[customRangeStart]
  /// `/[customRangeEnd]` mirror [ReportPeriod] exactly (see
  /// `ReportsRepositoryImpl`, the only caller).
  ({DateTime start, DateTime end}) rangeFor(
    ReportPeriod period, {
    DateTime? customRangeStart,
    DateTime? customRangeEnd,
  }) {
    return switch (period) {
      ReportPeriod.today => (
          start: _today,
          end: _today.add(const Duration(days: 1))
        ),
      ReportPeriod.yesterday => (start: _yesterday, end: _today),
      ReportPeriod.last7Days => (
          start: _today.subtract(const Duration(days: 6)),
          end: _today.add(const Duration(days: 1)),
        ),
      ReportPeriod.last30Days => (
          start: _today.subtract(const Duration(days: 29)),
          end: _today.add(const Duration(days: 1)),
        ),
      ReportPeriod.thisMonth => (
          start: _thisMonthStart,
          end: DateTime(_today.year, _today.month + 1, 1),
        ),
      ReportPeriod.thisYear => (
          start: DateTime(_today.year, 1, 1),
          end: DateTime(_today.year + 1, 1, 1),
        ),
      ReportPeriod.custom => (
          start:
              customRangeStart == null ? _today : _dateOnly(customRangeStart),
          end: customRangeEnd == null
              ? _today.add(const Duration(days: 1))
              : _dateOnly(customRangeEnd).add(const Duration(days: 1)),
        ),
    };
  }

  /// Trend bucketing for Reports' Sales Trend chart — hourly for a
  /// single-day period, daily for anything up to ~2 months, monthly for a
  /// whole year, so the chart always has a sensible number of points
  /// rather than 365 daily bars for "This Year".
  List<LedgerTrendPoint> trendFor(DateTime start, DateTime end) {
    final span = end.difference(start);
    if (span <= const Duration(days: 1)) {
      return _hourlyBuckets(start);
    }
    if (span <= const Duration(days: 62)) {
      return _dailyBuckets(start, span.inDays);
    }
    final months = (span.inDays / 30).ceil().clamp(1, 12);
    return [
      for (var i = 0; i < months; i++)
        (
          label: _monthLabel(DateTime(start.year, start.month + i)),
          amount: _sumInRange(
            DateTime(start.year, start.month + i),
            DateTime(start.year, start.month + i + 1),
          ),
        ),
    ];
  }

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _monthLabel(DateTime month) => _monthLabels[month.month - 1];

  // ---------------------------------------------------------------------
  // Payment breakdown
  // ---------------------------------------------------------------------

  List<LedgerPaymentSlice> paymentBreakdownFor(List<SalesRecord> scoped) {
    final totals = <String, double>{};
    for (final record in scoped) {
      totals[record.paymentMethod] =
          (totals[record.paymentMethod] ?? 0) + record.total;
    }
    final revenue = scoped.fold(0.0, (sum, r) => sum + r.total);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries)
        (
          method: entry.key,
          amount: entry.value,
          percentage: revenue == 0 ? 0 : (entry.value / revenue) * 100,
        ),
    ];
  }

  List<LedgerPaymentSlice> get paymentBreakdown => paymentBreakdownFor(records);

  // ---------------------------------------------------------------------
  // Products / categories
  // ---------------------------------------------------------------------

  /// Aggregated per product across [scoped] records — `productId` falls
  /// back to the product name when absent (a sale recorded before this
  /// field existed, or a manually-entered cart line with no catalog
  /// product behind it) so it still groups sensibly rather than being
  /// dropped.
  List<
      ({
        String productId,
        String name,
        String? category,
        int unitsSold,
        double revenue
      })> topProductsFor(List<SalesRecord> scoped) {
    final byProduct = <String,
        ({String name, String? category, int unitsSold, double revenue})>{};
    for (final record in scoped) {
      for (final item in record.items) {
        final key = item.productId ?? item.name;
        final existing = byProduct[key];
        byProduct[key] = (
          name: item.name,
          category: item.category ?? existing?.category,
          unitsSold: (existing?.unitsSold ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.lineTotal,
        );
      }
    }
    final rows = byProduct.entries
        .map((e) => (
              productId: e.key,
              name: e.value.name,
              category: e.value.category,
              unitsSold: e.value.unitsSold,
              revenue: e.value.revenue,
            ))
        .toList()
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
    return rows;
  }

  List<({String category, double revenue})> categoryBreakdownFor(
      List<SalesRecord> scoped) {
    final totals = <String, double>{};
    for (final record in scoped) {
      for (final item in record.items) {
        final category = item.category;
        if (category == null || category.isEmpty) continue;
        totals[category] = (totals[category] ?? 0) + item.lineTotal;
      }
    }
    final rows = totals.entries
        .map((e) => (category: e.key, revenue: e.value))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return rows;
  }

  List<SalesRecord> recordsFor(DateTime start, DateTime end) =>
      _recordsInRange(start, end);

  /// Every recorded sale, most recent first — never period-filtered
  /// (mirrors `DemoBusinessSnapshot.recentTransactions`, which is likewise
  /// always "the most recent sales", independent of Reports' own period
  /// filter).
  List<SalesRecord> get mostRecent =>
      [...records]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
}
