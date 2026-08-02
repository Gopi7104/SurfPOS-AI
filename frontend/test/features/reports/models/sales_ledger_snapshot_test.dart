import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/reports/models/report_period.dart';
import 'package:surfpos_ai/features/reports/models/sales_ledger_snapshot.dart';
import 'package:surfpos_ai/features/reports/models/sales_record.dart';

SalesRecord _record({
  required DateTime occurredAt,
  required double total,
  String paymentMethod = 'CARD',
  String? customerName,
  List<SalesRecordItem> items = const [],
}) {
  return SalesRecord(
    id: 'id-${occurredAt.millisecondsSinceEpoch}',
    receiptNumber: 'R-${occurredAt.millisecondsSinceEpoch}',
    occurredAt: occurredAt,
    total: total,
    paymentMethod: paymentMethod,
    customerName: customerName,
    items: items,
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 14, 30);
  final today = DateTime(2026, 6, 15);
  final yesterday = DateTime(2026, 6, 14);

  group('SalesLedgerSnapshot — core KPIs', () {
    test('todaySales/todayOrders only count records within today', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today.add(const Duration(hours: 9)), total: 50),
        _record(occurredAt: today.add(const Duration(hours: 15)), total: 30),
        _record(
            occurredAt: yesterday.add(const Duration(hours: 9)), total: 100),
      ], now: now);

      expect(snapshot.todaySales, 80);
      expect(snapshot.todayOrders, 2);
      expect(snapshot.todayAverageOrderValue, 40);
    });

    test('todaySalesGrowth compares against yesterday, null with no prior day',
        () {
      final withYesterday = SalesLedgerSnapshot([
        _record(occurredAt: today.add(const Duration(hours: 9)), total: 150),
        _record(
            occurredAt: yesterday.add(const Duration(hours: 9)), total: 100),
      ], now: now);
      expect(withYesterday.todaySalesGrowth, 50);

      final withoutYesterday = SalesLedgerSnapshot([
        _record(occurredAt: today.add(const Duration(hours: 9)), total: 150),
      ], now: now);
      expect(withoutYesterday.todaySalesGrowth, isNull);
    });

    test('totalRevenue/totalOrders/averageOrderValue sum every record', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today, total: 10),
        _record(occurredAt: yesterday, total: 30),
      ], now: now);

      expect(snapshot.totalRevenue, 40);
      expect(snapshot.totalOrders, 2);
      expect(snapshot.averageOrderValue, 20);
    });

    test('isEmpty reflects whether any records exist', () {
      expect(SalesLedgerSnapshot(const [], now: now).isEmpty, isTrue);
      expect(
          SalesLedgerSnapshot([_record(occurredAt: today, total: 10)], now: now)
              .isEmpty,
          isFalse);
    });
  });

  group('SalesLedgerSnapshot — payment breakdown', () {
    test('groups by payment method with correct percentages', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today, total: 75, paymentMethod: 'CARD'),
        _record(occurredAt: today, total: 25, paymentMethod: 'CASH'),
      ], now: now);

      final breakdown = snapshot.paymentBreakdown;
      final card = breakdown.firstWhere((s) => s.method == 'CARD');
      final cash = breakdown.firstWhere((s) => s.method == 'CASH');

      expect(card.amount, 75);
      expect(card.percentage, 75);
      expect(cash.amount, 25);
      expect(cash.percentage, 25);
    });
  });

  group('SalesLedgerSnapshot — top products & category breakdown', () {
    test('aggregates units/revenue per product across multiple sales', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today, total: 30, items: const [
          SalesRecordItem(
              productId: 'p1',
              name: 'Wax',
              category: 'Accessories',
              quantity: 2,
              unitPrice: 10,
              lineTotal: 20),
          SalesRecordItem(
              productId: 'p2',
              name: 'Leash',
              category: 'Accessories',
              quantity: 1,
              unitPrice: 10,
              lineTotal: 10),
        ]),
        _record(occurredAt: today, total: 10, items: const [
          SalesRecordItem(
              productId: 'p1',
              name: 'Wax',
              category: 'Accessories',
              quantity: 1,
              unitPrice: 10,
              lineTotal: 10),
        ]),
      ], now: now);

      final scoped =
          snapshot.recordsFor(today, today.add(const Duration(days: 1)));
      final topProducts = snapshot.topProductsFor(scoped);

      expect(topProducts.first.productId, 'p1');
      expect(topProducts.first.unitsSold, 3);
      expect(topProducts.first.revenue, 30);

      final categories = snapshot.categoryBreakdownFor(scoped);
      expect(categories.single.category, 'Accessories');
      expect(categories.single.revenue, 40);
    });

    test('items with no productId still group by name', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today, total: 20, items: const [
          SalesRecordItem(
              name: 'Manual Entry', quantity: 2, unitPrice: 10, lineTotal: 20),
        ]),
      ], now: now);

      final topProducts = snapshot.topProductsFor(snapshot.records);
      expect(topProducts.single.name, 'Manual Entry');
      expect(topProducts.single.unitsSold, 2);
    });

    test('items with no category are excluded from category breakdown', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: today, total: 20, items: const [
          SalesRecordItem(
              name: 'Uncategorized', quantity: 1, unitPrice: 20, lineTotal: 20),
        ]),
      ], now: now);

      expect(snapshot.categoryBreakdownFor(snapshot.records), isEmpty);
    });
  });

  group('SalesLedgerSnapshot — rangeFor', () {
    test('today spans exactly the calendar day', () {
      final snapshot = SalesLedgerSnapshot(const [], now: now);
      final range = snapshot.rangeFor(ReportPeriod.today);

      expect(range.start, today);
      expect(range.end, today.add(const Duration(days: 1)));
    });

    test('last7Days spans the last 7 calendar days inclusive of today', () {
      final snapshot = SalesLedgerSnapshot(const [], now: now);
      final range = snapshot.rangeFor(ReportPeriod.last7Days);

      expect(range.start, today.subtract(const Duration(days: 6)));
      expect(range.end, today.add(const Duration(days: 1)));
    });
  });

  group('SalesLedgerSnapshot — recent transactions', () {
    test('mostRecent sorts newest first, independent of any period filter', () {
      final snapshot = SalesLedgerSnapshot([
        _record(occurredAt: yesterday, total: 10),
        _record(occurredAt: today, total: 20),
      ], now: now);

      expect(snapshot.mostRecent.first.occurredAt, today);
      expect(snapshot.mostRecent.last.occurredAt, yesterday);
    });
  });
}
