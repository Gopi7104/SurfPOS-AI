import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/customers/models/customer_draft.dart';
import 'package:surfpos_ai/features/customers/models/customer_model.dart';
import 'package:surfpos_ai/features/customers/models/customer_query.dart';
import 'package:surfpos_ai/features/customers/models/customer_purchase.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_api_storage.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_purchase_api_storage.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_repository_impl.dart';

/// In-memory doubles for the Firebase-backed API storage classes — no real
/// HTTP call involved, same "implements the concrete class, override just
/// its public readAll/writeAll" pattern `product_image_local_storage_test.dart`
/// already uses for [SecureStorageService].
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

CustomerRepositoryImpl _repository() {
  return CustomerRepositoryImpl(
    localStorage: _FakeCustomerApiStorage(),
    purchaseLocalStorage: _FakeCustomerPurchaseApiStorage(),
  );
}

/// Seeds a customer directly into storage (bypassing `createCustomer`,
/// which always stamps `memberSince` as "now") so tests can control
/// `memberSince`/`lastPurchaseAt` precisely — needed to exercise the
/// "established, not new" side of [computeCustomerSegments].
Future<CustomerModel> _seedCustomer(
  _FakeCustomerApiStorage localStorage, {
  required String id,
  required DateTime memberSince,
}) async {
  final customer = CustomerModel(
    id: id,
    firstName: 'Seed',
    lastName: id,
    phone: '000',
    memberSince: memberSince,
  );
  final existing = await localStorage.readAll();
  await localStorage.writeAll([...existing, customer]);
  return customer;
}

void main() {
  group('CustomerRepositoryImpl — search', () {
    test('matches by name, phone, email, tag, and purchased product', () async {
      final repository = _repository();
      final alex = await repository.createCustomer(const CustomerDraft(
        firstName: 'Alex',
        lastName: 'Rivera',
        phone: '555-0100',
        email: 'alex@example.com',
        tags: ['Wholesale'],
      ));
      await repository.createCustomer(const CustomerDraft(
        firstName: 'Sam',
        lastName: 'Lee',
        phone: '555-0200',
      ));
      await repository.recordPurchase(
        alex.id,
        amount: 25,
        itemNames: const ['Surfboard Wax'],
        paymentMethod: 'CARD',
        purchasedAt: DateTime(2026, 1, 1),
      );

      final byName =
          await repository.listCustomers(const CustomerQuery(search: 'Alex'));
      final byPhone =
          await repository.listCustomers(const CustomerQuery(search: '0100'));
      final byEmail = await repository
          .listCustomers(const CustomerQuery(search: 'alex@example.com'));
      final byTag = await repository
          .listCustomers(const CustomerQuery(search: 'Wholesale'));
      final byProduct = await repository
          .listCustomers(const CustomerQuery(search: 'Surfboard Wax'));
      final noMatch = await repository
          .listCustomers(const CustomerQuery(search: 'nonexistent'));

      for (final page in [byName, byPhone, byEmail, byTag, byProduct]) {
        expect(page.items.map((c) => c.id), [alex.id]);
      }
      expect(noMatch.items, isEmpty);
    });

    test('the vip filter only returns customers tagged VIP', () async {
      final repository = _repository();
      final vip = await repository.createCustomer(const CustomerDraft(
          firstName: 'V', lastName: 'IP', phone: '1', tags: ['VIP']));
      await repository.createCustomer(
          const CustomerDraft(firstName: 'Not', lastName: 'Vip', phone: '2'));

      final page = await repository
          .listCustomers(const CustomerQuery(filter: CustomerFilter.vip));

      expect(page.items.map((c) => c.id), [vip.id]);
    });

    test('the highestSpending filter sorts by lifetime spend descending',
        () async {
      final repository = _repository();
      final low = await repository.createCustomer(const CustomerDraft(
          firstName: 'Low', lastName: 'Spender', phone: '1'));
      final high = await repository.createCustomer(const CustomerDraft(
          firstName: 'High', lastName: 'Spender', phone: '2'));
      await repository.recordPurchase(low.id,
          amount: 10,
          itemNames: const [],
          paymentMethod: 'CARD',
          purchasedAt: DateTime(2026));
      await repository.recordPurchase(high.id,
          amount: 500,
          itemNames: const [],
          paymentMethod: 'CARD',
          purchasedAt: DateTime(2026));

      final page = await repository.listCustomers(
          const CustomerQuery(filter: CustomerFilter.highestSpending));

      expect(page.items.map((c) => c.id).toList(), [high.id, low.id]);
    });
  });

  group('CustomerRepositoryImpl — recordPurchase', () {
    test(
        'updates lifetime spend, order count, last purchase date, and loyalty points',
        () async {
      final repository = _repository();
      final customer = await repository.createCustomer(const CustomerDraft(
          firstName: 'Alex', lastName: 'Rivera', phone: '555-0100'));
      final purchaseDate = DateTime(2026, 3, 1);

      final updated = await repository.recordPurchase(
        customer.id,
        amount: 42.75,
        itemNames: const ['Wax', 'Leash'],
        paymentMethod: 'CARD',
        purchasedAt: purchaseDate,
        receiptNumber: 'R-1',
      );

      expect(updated.lifetimeSpend, 42.75);
      expect(updated.totalOrders, 1);
      expect(updated.lastPurchaseAt, purchaseDate);
      expect(updated.loyaltyPoints, 42);
      expect(updated.lifetimePoints, 42);
    });

    test('accumulates across multiple purchases', () async {
      final repository = _repository();
      final customer = await repository.createCustomer(const CustomerDraft(
          firstName: 'Alex', lastName: 'Rivera', phone: '555-0100'));

      await repository.recordPurchase(customer.id,
          amount: 10,
          itemNames: const [],
          paymentMethod: 'CARD',
          purchasedAt: DateTime(2026, 1));
      final second = await repository.recordPurchase(customer.id,
          amount: 20,
          itemNames: const [],
          paymentMethod: 'CASH',
          purchasedAt: DateTime(2026, 2));

      expect(second.lifetimeSpend, 30);
      expect(second.totalOrders, 2);
      expect(second.loyaltyPoints, 30);
    });

    test('throws when the customer does not exist', () async {
      final repository = _repository();

      expect(
        () => repository.recordPurchase('missing',
            amount: 10,
            itemNames: const [],
            paymentMethod: 'CARD',
            purchasedAt: DateTime(2026)),
        throwsStateError,
      );
    });
  });

  group('CustomerRepositoryImpl — getFavoriteProducts', () {
    test('ranks products by how often they were purchased', () async {
      final repository = _repository();
      final customer = await repository.createCustomer(const CustomerDraft(
          firstName: 'Alex', lastName: 'Rivera', phone: '555-0100'));
      await repository.recordPurchase(customer.id,
          amount: 10,
          itemNames: const ['Wax'],
          paymentMethod: 'CARD',
          purchasedAt: DateTime(2026, 1));
      await repository.recordPurchase(customer.id,
          amount: 10,
          itemNames: const ['Wax', 'Leash'],
          paymentMethod: 'CARD',
          purchasedAt: DateTime(2026, 2));

      final favorites = await repository.getFavoriteProducts(customer.id);

      expect(favorites.first.name, 'Wax');
      expect(favorites.first.timesPurchased, 2);
      expect(favorites.any((f) => f.name == 'Leash' && f.timesPurchased == 1),
          isTrue);
    });

    test('is empty for a customer with no purchases', () async {
      final repository = _repository();
      final customer = await repository.createCustomer(const CustomerDraft(
          firstName: 'Alex', lastName: 'Rivera', phone: '555-0100'));

      expect(await repository.getFavoriteProducts(customer.id), isEmpty);
    });
  });

  group('CustomerRepositoryImpl — getStats', () {
    test('computes real returningCustomers/inactiveCustomers/lifetimeRevenue',
        () async {
      final localStorage = _FakeCustomerApiStorage();
      final repository = CustomerRepositoryImpl(
        localStorage: localStorage,
        purchaseLocalStorage: _FakeCustomerPurchaseApiStorage(),
      );
      final longAgo = DateTime.now().subtract(const Duration(days: 200));
      final returning = await _seedCustomer(localStorage,
          id: 'returning', memberSince: longAgo);
      await _seedCustomer(localStorage,
          id: 'never-purchased', memberSince: longAgo);
      await repository.recordPurchase(returning.id,
          amount: 50,
          itemNames: const [],
          paymentMethod: 'CARD',
          purchasedAt: DateTime.now());
      await repository.recordPurchase(returning.id,
          amount: 25,
          itemNames: const [],
          paymentMethod: 'CARD',
          purchasedAt: DateTime.now());

      final stats = await repository.getStats();

      expect(stats.returningCustomers, 1);
      expect(stats.inactiveCustomers, 1);
      expect(stats.lifetimeRevenue, 75);
    });

    test('returns the shared empty stats record with no customers', () async {
      final repository = _repository();

      final stats = await repository.getStats();

      expect(stats.totalCustomers, 0);
      expect(stats.lifetimeRevenue, 0.0);
    });
  });
}
