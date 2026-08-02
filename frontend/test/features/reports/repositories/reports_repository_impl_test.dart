import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/reports/models/report_period.dart';
import 'package:surfpos_ai/features/reports/models/sales_record.dart';
import 'package:surfpos_ai/features/reports/repositories/reports_repository_impl.dart';
import 'package:surfpos_ai/features/reports/repositories/sales_ledger_repository.dart';

import '../../inventory/fakes/fake_inventory_repository.dart';

class _FakeSalesLedgerRepository implements SalesLedgerRepository {
  _FakeSalesLedgerRepository(this._records);
  final List<SalesRecord> _records;

  @override
  Future<void> recordSale(SalesRecord record) async {}

  @override
  Future<List<SalesRecord>> getAll() async => _records;
}

void main() {
  group('ReportsRepositoryImpl — no real sales yet', () {
    test('every sales-shaped section is genuinely empty/zero, never fabricated',
        () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(const []),
      );

      final snapshot = await repository.loadReports(period: ReportPeriod.today);

      expect(snapshot.salesSummary.totalRevenue, 0);
      expect(snapshot.orderSummary.todayOrders, 0);
      expect(snapshot.topProducts, isEmpty);
      expect(snapshot.salesTrend, isNotEmpty); // hourly buckets, all zero
      expect(snapshot.salesTrend.every((p) => p.amount == 0), isTrue);
      expect(snapshot.categoryBreakdown, isEmpty);
      expect(snapshot.recentTransactions, isEmpty);
      expect(snapshot.paymentBreakdown, isEmpty);
    });
  });

  group('ReportsRepositoryImpl — with real recorded sales', () {
    // `ReportsRepositoryImpl` anchors "today"/"yesterday" on the real
    // `DateTime.now()` (no injectable clock — see `SalesLedgerSnapshot`'s
    // header comment on why real sale times matter), so these fixtures
    // must be relative to the real now rather than a fixed calendar date.
    final realNow = DateTime.now();
    final today = DateTime(realNow.year, realNow.month, realNow.day);

    List<SalesRecord> records() => [
          SalesRecord(
            id: 's1',
            receiptNumber: 'R-1',
            occurredAt: today.add(const Duration(hours: 9)),
            total: 50,
            paymentMethod: 'CARD',
            customerName: 'Alex Rivera',
            items: const [
              SalesRecordItem(
                productId: 'p1',
                name: 'Wax',
                category: 'Accessories',
                quantity: 2,
                unitPrice: 25,
                lineTotal: 50,
              ),
            ],
          ),
          SalesRecord(
            id: 's2',
            receiptNumber: 'R-2',
            occurredAt: today.add(const Duration(hours: 11)),
            total: 20,
            paymentMethod: 'CASH',
            items: const [
              SalesRecordItem(
                productId: 'p1',
                name: 'Wax',
                category: 'Accessories',
                quantity: 1,
                unitPrice: 20,
                lineTotal: 20,
              ),
            ],
          ),
        ];

    test('computes real sales summary/order summary for today', () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(records()),
      );

      final snapshot = await repository.loadReports(period: ReportPeriod.today);

      expect(snapshot.salesSummary.totalRevenue, 70);
      expect(snapshot.orderSummary.todayOrders, 2);
      expect(snapshot.orderSummary.completedOrders, 2);
      expect(snapshot.orderSummary.averageOrderValue, 35);
    });

    test('aggregates real top products and category breakdown', () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(records()),
      );

      final snapshot = await repository.loadReports(period: ReportPeriod.today);

      expect(snapshot.topProducts.single.productId, 'p1');
      expect(snapshot.topProducts.single.unitsSold, 3);
      expect(snapshot.topProducts.single.category, 'Accessories');
      expect(snapshot.categoryBreakdown.single.category, 'Accessories');
      expect(snapshot.categoryBreakdown.single.revenue, 70);
      expect(snapshot.categoryBreakdown.single.percentage, 100);
    });

    test('splits real payment breakdown by method', () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(records()),
      );

      final snapshot = await repository.loadReports(period: ReportPeriod.today);

      final card =
          snapshot.paymentBreakdown.firstWhere((s) => s.method == 'CARD');
      final cash =
          snapshot.paymentBreakdown.firstWhere((s) => s.method == 'CASH');
      expect(card.amount, 50);
      expect(cash.amount, 20);
    });

    test(
        'recent transactions include the real customer name and are newest first',
        () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(records()),
      );

      final snapshot = await repository.loadReports(period: ReportPeriod.today);

      expect(snapshot.recentTransactions.first.receiptNumber, 'R-2');
      expect(snapshot.recentTransactions.last.customerName, 'Alex Rivera');
    });

    test(
        'a period with no sales in range excludes them from the scoped figures',
        () async {
      final repository = ReportsRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(),
        salesLedgerRepository: _FakeSalesLedgerRepository(records()),
      );

      final snapshot =
          await repository.loadReports(period: ReportPeriod.yesterday);

      expect(snapshot.orderSummary.completedOrders, 0);
      expect(snapshot.topProducts, isEmpty);
      // Recent transactions are never period-scoped — still shows real sales.
      expect(snapshot.recentTransactions, hasLength(2));
    });
  });

  test(
      'real InventoryOverview is always read from InventoryRepository, independent of sales',
      () async {
    final repository = ReportsRepositoryImpl(
      inventoryRepository: FakeInventoryRepository(
          listCategories: () async => const ['Wax', 'Boards']),
      salesLedgerRepository: _FakeSalesLedgerRepository(const []),
    );

    final snapshot = await repository.loadReports(period: ReportPeriod.today);

    expect(snapshot.inventoryOverview.categoriesCount, 2);
  });
}
