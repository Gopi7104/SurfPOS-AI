import '../../reports/models/recent_transaction.dart';
import 'business_insight.dart';
import 'demo_customer.dart';
import 'demo_product.dart';
import 'demo_receipt.dart';
import 'demo_sale.dart';
import 'payment_breakdown_slice.dart';
import 'revenue_period.dart';

/// One point on a revenue/sales-trend chart — [label] is already formatted
/// for whatever bucketing produced it (an hour, a weekday, a week number).
class DemoTrendPoint {
  const DemoTrendPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

/// Everything the redesigned Dashboard renders once "Generate Demo
/// Business" has been used — entirely local, presentation-only data (see
/// `DemoDataGenerator`'s header comment). Only the raw records
/// ([products]/[customers]/[sales]/[receipts]) are persisted; every KPI/
/// chart/insight below is derived on read so there's a single source of
/// truth and nothing can drift out of sync with it.
///
/// All "today"/"this week"/"this month" windows are anchored on
/// [latestSaleDay] — the calendar day of the most recent generated sale —
/// rather than the real `DateTime.now()`. That's deliberate: it means the
/// dataset keeps looking coherent and "current" no matter how many real
/// days pass before someone next opens the Dashboard, without needing to
/// regenerate.
class DemoBusinessSnapshot {
  const DemoBusinessSnapshot({
    required this.merchantName,
    required this.storeName,
    required this.generatedAt,
    required this.categories,
    required this.products,
    required this.customers,
    required this.sales,
    required this.receipts,
  });

  final String merchantName;
  final String storeName;
  final DateTime generatedAt;
  final List<String> categories;
  final List<DemoProduct> products;
  final List<DemoCustomer> customers;
  final List<DemoSale> sales;
  final List<DemoReceipt> receipts;

  static const _paymentMethods = ['Cash', 'Card', 'Mobile Payment', 'Test'];

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime get latestSaleDay => sales.isEmpty
      ? _dateOnly(generatedAt)
      : _dateOnly(
          sales.map((s) => s.time).reduce((a, b) => a.isAfter(b) ? a : b));

  double _sumInRange(DateTime startInclusive, DateTime endExclusive) {
    return sales
        .where((s) =>
            !s.time.isBefore(startInclusive) && s.time.isBefore(endExclusive))
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  int _countInRange(DateTime startInclusive, DateTime endExclusive) {
    return sales
        .where((s) =>
            !s.time.isBefore(startInclusive) && s.time.isBefore(endExclusive))
        .length;
  }

  // ---------------------------------------------------------------------
  // Business Snapshot KPIs
  // ---------------------------------------------------------------------

  DateTime get _today => latestSaleDay;
  DateTime get _yesterday => _today.subtract(const Duration(days: 1));
  DateTime get _thisWeekStart =>
      _today.subtract(Duration(days: _today.weekday - 1));
  DateTime get _thisMonthStart => DateTime(_today.year, _today.month, 1);

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

  double get totalRevenue => sales.fold(0.0, (sum, s) => sum + s.amount);
  double get totalCost => sales.fold(0.0, (sum, s) => sum + s.costAmount);
  double get totalProfit => totalRevenue - totalCost;
  int get totalOrders => sales.length;

  double get averageOrderValue =>
      totalOrders == 0 ? 0 : totalRevenue / totalOrders;

  double get todayAverageOrderValue =>
      todayOrders == 0 ? averageOrderValue : todaySales / todayOrders;

  int get customersCount => customers.length;

  // ---------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------

  List<DemoProduct> get bestSellers {
    final sorted = [...products]
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
    return sorted;
  }

  List<DemoProduct> get lowStockProducts {
    final low = products.where((p) => p.isLowStock).toList()
      ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    return low;
  }

  // ---------------------------------------------------------------------
  // Payment breakdown
  // ---------------------------------------------------------------------

  List<PaymentBreakdownSlice> get paymentBreakdown {
    final totals = {for (final m in _paymentMethods) m: 0.0};
    for (final sale in sales) {
      totals[sale.paymentMethod] =
          (totals[sale.paymentMethod] ?? 0) + sale.amount;
    }
    final revenue = totalRevenue;
    return _paymentMethods
        .map((method) => PaymentBreakdownSlice(
              method: method,
              amount: totals[method] ?? 0,
              percentage:
                  revenue == 0 ? 0 : ((totals[method] ?? 0) / revenue) * 100,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Recent transactions
  // ---------------------------------------------------------------------

  List<RecentTransaction> get recentTransactions {
    final sorted = [...sales]..sort((a, b) => b.time.compareTo(a.time));
    return sorted
        .take(20)
        .map((sale) => RecentTransaction(
              receiptNumber: sale.receiptNumber,
              customerName: sale.customerName,
              amount: sale.amount,
              status: sale.status,
              paymentMethod: sale.paymentMethod,
              time: sale.time,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Charts
  // ---------------------------------------------------------------------

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  /// Day-0-of-next-month is the last day of this month (`DateTime`'s own
  /// month-overflow normalization) — so the Month bucketing below always
  /// covers the whole month, not just its first 28 days.
  int get _daysInThisMonth => DateTime(_today.year, _today.month + 1, 0).day;

  int get _weeksInThisMonth => (_daysInThisMonth / 7).ceil();

  /// The Revenue Chart's Today/Week/Month toggle — different bucketing per
  /// period so each view is genuinely useful, not just a re-scaled copy of
  /// the others.
  List<DemoTrendPoint> revenueTrend(RevenuePeriod period) {
    return switch (period) {
      RevenuePeriod.today => [
          for (var hour = 0; hour < 24; hour += 4)
            DemoTrendPoint(
              label: _hourLabel(hour),
              amount: _sumInRange(
                _today.add(Duration(hours: hour)),
                _today.add(Duration(hours: hour + 4)),
              ),
            ),
        ],
      RevenuePeriod.week => [
          for (var i = 0; i < 7; i++)
            DemoTrendPoint(
              label: _weekdayLabels[i],
              amount: _sumInRange(
                _thisWeekStart.add(Duration(days: i)),
                _thisWeekStart.add(Duration(days: i + 1)),
              ),
            ),
        ],
      RevenuePeriod.month => [
          for (var week = 0; week < _weeksInThisMonth; week++)
            DemoTrendPoint(
              label: 'Week ${week + 1}',
              amount: _sumInRange(
                _thisMonthStart.add(Duration(days: week * 7)),
                _thisMonthStart.add(
                    Duration(days: _daysInThisMonth.clamp(0, (week + 1) * 7))),
              ),
            ),
        ],
    };
  }

  /// The separate Sales Trend line chart — the last 14 calendar days,
  /// always at daily granularity regardless of the Revenue Chart's toggle.
  List<DemoTrendPoint> get salesTrend {
    return [
      for (var i = 13; i >= 0; i--)
        DemoTrendPoint(
          label: _dayLabel(_today.subtract(Duration(days: i))),
          amount: _sumInRange(
            _today.subtract(Duration(days: i)),
            _today.subtract(Duration(days: i - 1)),
          ),
        ),
    ];
  }

  String _hourLabel(int hour) {
    final period = hour < 12 ? 'am' : 'pm';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h$period';
  }

  String _dayLabel(DateTime day) => '${day.day}/${day.month}';

  // ---------------------------------------------------------------------
  // Business Insights
  // ---------------------------------------------------------------------

  List<BusinessInsight> get insights {
    final result = <BusinessInsight>[];

    final growth = thisWeekGrowth;
    if (growth != null) {
      result.add(BusinessInsight(
        kind: InsightKind.growth,
        message: growth >= 0
            ? 'Sales increased ${growth.toStringAsFixed(0)}% this week'
            : 'Sales dipped ${growth.abs().toStringAsFixed(0)}% this week',
      ));
    }

    final categoryRevenue = <String, double>{};
    for (final product in products) {
      categoryRevenue[product.category] =
          (categoryRevenue[product.category] ?? 0) + product.revenue;
    }
    if (categoryRevenue.isNotEmpty) {
      final topCategory =
          categoryRevenue.entries.reduce((a, b) => a.value >= b.value ? a : b);
      result.add(BusinessInsight(
        kind: InsightKind.category,
        message: '${topCategory.key} is your best-selling category',
      ));
    }

    if (customers.isNotEmpty) {
      final topCustomer =
          [...customers].reduce((a, b) => a.totalSpend >= b.totalSpend ? a : b);
      result.add(BusinessInsight(
        kind: InsightKind.customer,
        message:
            '${topCustomer.name} is your top customer, \$${topCustomer.totalSpend.toStringAsFixed(0)} spent',
      ));
    }

    if (products.isNotEmpty) {
      final fastestMover =
          [...products].reduce((a, b) => a.unitsSold >= b.unitsSold ? a : b);
      if (fastestMover.unitsSold > 0) {
        result.add(BusinessInsight(
          kind: InsightKind.inventory,
          message: '${fastestMover.name} is your fastest-moving product',
        ));
      }
    }

    final lowStock = lowStockProducts;
    if (lowStock.isNotEmpty) {
      result.add(BusinessInsight(
        kind: InsightKind.lowStock,
        message: '${lowStock.length} product${lowStock.length == 1 ? '' : 's'} '
            'running low on stock',
      ));
    }

    return result;
  }

  Map<String, dynamic> toJson() => {
        'merchantName': merchantName,
        'storeName': storeName,
        'generatedAt': generatedAt.millisecondsSinceEpoch,
        'categories': categories,
        'products': products.map((p) => p.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'sales': sales.map((s) => s.toJson()).toList(),
        'receipts': receipts.map((r) => r.toJson()).toList(),
      };

  factory DemoBusinessSnapshot.fromJson(Map<String, dynamic> json) {
    return DemoBusinessSnapshot(
      merchantName: json['merchantName'] as String,
      storeName: json['storeName'] as String,
      generatedAt:
          DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] as int),
      categories: (json['categories'] as List<dynamic>).cast<String>(),
      products: (json['products'] as List<dynamic>)
          .map((p) => DemoProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      customers: (json['customers'] as List<dynamic>)
          .map((c) => DemoCustomer.fromJson(c as Map<String, dynamic>))
          .toList(),
      sales: (json['sales'] as List<dynamic>)
          .map((s) => DemoSale.fromJson(s as Map<String, dynamic>))
          .toList(),
      receipts: (json['receipts'] as List<dynamic>)
          .map((r) => DemoReceipt.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
