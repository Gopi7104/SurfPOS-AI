import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/ai/models/ai_chat_reply.dart';
import 'package:surfpos_ai/features/ai/services/client_ai_tool_executor.dart';
import 'package:surfpos_ai/features/billing/providers/billing_providers.dart';
import 'package:surfpos_ai/features/customers/models/customer_draft.dart';
import 'package:surfpos_ai/features/customers/models/customer_model.dart';
import 'package:surfpos_ai/features/customers/models/customer_purchase.dart';
import 'package:surfpos_ai/features/customers/providers/customer_providers.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_api_storage.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_purchase_api_storage.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_business_snapshot.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_customer.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_product.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_sale.dart';
import 'package:surfpos_ai/features/inventory/models/product_model.dart';
import 'package:surfpos_ai/features/inventory/models/product_status.dart';
import 'package:surfpos_ai/features/reports/models/inventory_overview.dart';
import 'package:surfpos_ai/features/reports/models/order_summary.dart';
import 'package:surfpos_ai/features/reports/models/reports_snapshot.dart';
import 'package:surfpos_ai/features/reports/models/sales_summary.dart';
import 'package:surfpos_ai/features/reports/repositories/reports_repository.dart';
import 'package:surfpos_ai/features/reports/providers/reports_providers.dart';
import 'package:surfpos_ai/features/reports/models/recent_transaction.dart';

/// `ClientAiToolExecutor` takes a `Ref`, not a `ProviderContainer` — this
/// throwaway provider is the standard way to obtain a real, container-scoped
/// `Ref` (with every override below applied) in a plain `test()`, without a
/// widget tree.
final _executorProvider = Provider((ref) => ClientAiToolExecutor(ref));

const _uid = 'uid-1';

class _FakeSecureStorageService implements SecureStorageService {
  _FakeSecureStorageService([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

/// In-memory doubles for the Firebase-backed customer API storage classes —
/// customer/purchase data now persists server-side (see
/// backend/src/modules/customers/), not via [SecureStorageService], so
/// `customerRepositoryProvider` no longer flows through
/// [secureStorageServiceProvider] and needs these overridden directly
/// instead — same "implements the concrete class" pattern as
/// `_FakeSecureStorageService` above.
class _FakeCustomerApiStorage implements CustomerApiStorage {
  List<CustomerModel> _items = [];

  @override
  Future<List<CustomerModel>> readAll() async => _items;

  @override
  Future<void> writeAll(List<CustomerModel> customers) async {
    _items = customers;
  }
}

class _FakeCustomerPurchaseApiStorage implements CustomerPurchaseApiStorage {
  List<CustomerPurchase> _items = [];

  @override
  Future<List<CustomerPurchase>> readAll() async => _items;

  @override
  Future<void> writeAll(List<CustomerPurchase> purchases) async {
    _items = purchases;
  }
}

class _FakeReportsRepository implements ReportsRepository {
  _FakeReportsRepository(this.snapshot);
  final ReportsSnapshot snapshot;

  @override
  Future<ReportsSnapshot> loadReports({required period, customRange}) async =>
      snapshot;
}

ProductModel _product({
  required String id,
  required String name,
  double sellingPrice = 10,
}) {
  final now = DateTime(2026);
  return ProductModel(
    id: id,
    name: name,
    sku: 'SKU-$id',
    unit: 'unit',
    price: sellingPrice,
    costPrice: sellingPrice / 2,
    taxPercentage: 0,
    discountPercentage: 0,
    stockQuantity: 10,
    status: ProductStatus.active,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _makeContainer({
  Map<String, String>? storageSeed,
  ReportsSnapshot? reportsSnapshot,
}) {
  return ProviderContainer(overrides: [
    secureStorageServiceProvider
        .overrideWithValue(_FakeSecureStorageService(storageSeed)),
    customerApiStorageProvider.overrideWithValue(_FakeCustomerApiStorage()),
    customerPurchaseApiStorageProvider
        .overrideWithValue(_FakeCustomerPurchaseApiStorage()),
    if (reportsSnapshot != null)
      reportsRepositoryProvider(_uid)
          .overrideWithValue(_FakeReportsRepository(reportsSnapshot)),
  ]);
}

Map<String, String> _demoSeed(DemoBusinessSnapshot snapshot) =>
    {'demo_data.snapshot.$_uid': jsonEncode(snapshot.toJson())};

void main() {
  group('ClientAiToolExecutor — billing (real, synchronous cart)', () {
    test(
        'currentCart / cartTotal / itemCount are honest when the cart is empty',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final cartTotal = await executor.execute(_uid,
          const ClientToolRequest(tool: 'billing', function: 'cartTotal'));
      final itemCount = await executor.execute(_uid,
          const ClientToolRequest(tool: 'billing', function: 'itemCount'));

      expect(cartTotal, 'Your cart is empty.');
      expect(itemCount, 'You have 0 item(s) in the cart.');
    });

    test(
        'cartTotal/discount/tax reflect real items added via the real BillingController',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(billingControllerProvider(_uid).notifier)
          .selectSearchResult(
              _product(id: 'p1', name: 'Wax', sellingPrice: 20));
      final executor = container.read(_executorProvider);

      final total = await executor.execute(_uid,
          const ClientToolRequest(tool: 'billing', function: 'cartTotal'));
      final products = await executor.execute(
          _uid,
          const ClientToolRequest(
              tool: 'billing', function: 'currentProducts'));

      expect(total, contains('20.00'));
      expect(products, contains('Wax'));
    });
  });

  group('ClientAiToolExecutor — dashboard/reports (demo-backed)', () {
    test('honestly reports no data when demo data was never generated',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(_uid,
          const ClientToolRequest(tool: 'dashboard', function: 'revenueToday'));

      expect(result, contains('generate demo'));
    });

    test('reports real figures once demo data exists', () async {
      final now = DateTime.now();
      final snapshot = DemoBusinessSnapshot(
        merchantName: 'Test Shop',
        storeName: 'Main',
        generatedAt: now,
        categories: const ['Wax'],
        products: [
          const DemoProduct(
            id: 'p1',
            name: 'Wax',
            category: 'Wax',
            price: 10,
            costPrice: 5,
            stockQuantity: 20,
            lowStockThreshold: 5,
            unitsSold: 3,
            colorSeed: 0,
          ),
        ],
        customers: const [
          DemoCustomer(id: 'c1', name: 'Alex', totalSpend: 100, totalOrders: 2),
        ],
        sales: [
          DemoSale(
            id: 's1',
            receiptNumber: 'R-1',
            time: now,
            amount: 30,
            costAmount: 15,
            paymentMethod: 'Card',
            productId: 'p1',
            productName: 'Wax',
            customerName: 'Alex',
            status: TransactionStatus.successful,
          ),
        ],
        receipts: const [],
      );
      final container = _makeContainer(storageSeed: _demoSeed(snapshot));
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final revenue = await executor.execute(_uid,
          const ClientToolRequest(tool: 'dashboard', function: 'revenueToday'));
      final bestSeller = await executor.execute(_uid,
          const ClientToolRequest(tool: 'reports', function: 'bestSeller'));

      expect(revenue, contains('30.00'));
      expect(revenue, contains('demo data'));
      expect(bestSeller, contains('Wax'));
    });

    test('businessInsights joins every generated insight message', () async {
      final now = DateTime.now();
      final snapshot = DemoBusinessSnapshot(
        merchantName: 'Test Shop',
        storeName: 'Main',
        generatedAt: now,
        categories: const [],
        products: const [],
        customers: const [],
        sales: const [],
        receipts: const [],
      );
      final container = _makeContainer(storageSeed: _demoSeed(snapshot));
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(
          _uid,
          const ClientToolRequest(
              tool: 'dashboard', function: 'businessInsights'));

      expect(snapshot.insights, isEmpty);
      expect(result, contains("don't have enough data"));
    });

    test(
        'reports.inventoryHealth reads the real InventoryRepository via ReportsRepository, never demo data',
        () async {
      final container = _makeContainer(
        reportsSnapshot: ReportsSnapshot(
          salesSummary: SalesSummary.empty(),
          orderSummary: OrderSummary.empty(),
          inventoryOverview: const InventoryOverview(
            productsCount: 12,
            lowStockCount: 3,
            outOfStockCount: 1,
            categoriesCount: 4,
            isApproximate: false,
          ),
          topProducts: const [],
          salesTrend: const [],
          categoryBreakdown: const [],
          recentTransactions: const [],
          paymentBreakdown: const [],
          generatedAt: DateTime.now(),
        ),
      );
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(
          _uid,
          const ClientToolRequest(
              tool: 'reports', function: 'inventoryHealth'));

      expect(result, contains('12 product'));
      expect(result, contains('3 low stock'));
      expect(result, contains('1 out of stock'));
    });
  });

  group('ClientAiToolExecutor — customer (real, device-local)', () {
    test('count is honest (0) with no customers yet', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(
          _uid, const ClientToolRequest(tool: 'customer', function: 'count'));

      expect(result, 'You have 0 customer(s).');
    });

    test('topCustomer is honest when no purchase has ever been recorded',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(_uid,
          const ClientToolRequest(tool: 'customer', function: 'topCustomer'));

      expect(result, contains("don't have any purchase history"));
    });

    test('vipCustomers is honest with none yet', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final executor = container.read(_executorProvider);

      final result = await executor.execute(_uid,
          const ClientToolRequest(tool: 'customer', function: 'vipCustomers'));

      expect(result, contains("don't have any VIP"));
    });

    test('topCustomer/vipCustomers/loyalty reflect a real recorded purchase',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final repository = container.read(customerRepositoryProvider(_uid));
      final customer = await repository.createCustomer(const CustomerDraft(
        firstName: 'Alex',
        lastName: 'Rivera',
        phone: '555-0100',
        tags: ['VIP'],
      ));
      await repository.recordPurchase(
        customer.id,
        amount: 150,
        itemNames: const ['Surfboard Wax'],
        paymentMethod: 'CARD',
        purchasedAt: DateTime.now(),
      );
      final executor = container.read(_executorProvider);

      final top = await executor.execute(_uid,
          const ClientToolRequest(tool: 'customer', function: 'topCustomer'));
      final loyalty = await executor.execute(
          _uid,
          const ClientToolRequest(
              tool: 'customer',
              function: 'loyalty',
              params: {'query': 'Alex'}));

      expect(top, contains('Alex Rivera'));
      expect(top, contains('150.00'));
      expect(loyalty, contains('150 loyalty points'));
    });
  });

  test(
      'unknown tool/function combinations never throw, always a plain honest string',
      () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final executor = container.read(_executorProvider);

    final result = await executor.execute(
        _uid, const ClientToolRequest(tool: 'nope', function: 'nope'));

    expect(result, isA<String>());
  });
}
