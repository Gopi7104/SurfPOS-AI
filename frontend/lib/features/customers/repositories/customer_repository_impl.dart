import 'dart:math';

import '../models/customer_draft.dart';
import '../models/customer_model.dart';
import '../models/customer_note.dart';
import '../models/customer_page.dart';
import '../models/customer_purchase.dart';
import '../models/customer_query.dart';
import '../models/customer_segment.dart';
import '../models/customer_stats.dart';
import '../models/customer_status.dart';
import '../models/loyalty.dart';
import 'customer_api_storage.dart';
import 'customer_purchase_api_storage.dart';
import 'customer_repository.dart';

/// Reads/writes the whole customer list via [CustomerApiStorage], and the
/// whole purchase-history list via [CustomerPurchaseApiStorage] (Firebase-
/// backed, see backend/src/modules/customers/ — previously per-device
/// secure storage only). Every write is read-modify-write-the-whole-list,
/// same simplification `ProductImageLocalStorage`/product filtering already
/// use for this app's target small-retailer scale.
///
/// [recordPurchase] is the *only* write path for a customer's lifetime
/// stats (`lifetimeSpend`/`totalOrders`/`lastPurchaseAt`) and loyalty
/// points — called once per completed sale from Billing's payment-success
/// hook (`PaymentStatusPage`), never from within this module. Before Phase
/// CRM-1 those fields stayed at their create-time zero forever because
/// nothing in the app ever called back into this module after a sale; this
/// is that missing call, not a redesign of anything else.
class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl({
    required CustomerApiStorage localStorage,
    required CustomerPurchaseApiStorage purchaseLocalStorage,
  })  : _localStorage = localStorage,
        _purchaseLocalStorage = purchaseLocalStorage;

  final CustomerApiStorage _localStorage;
  final CustomerPurchaseApiStorage _purchaseLocalStorage;

  static const _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  String _generateId([String prefix = 'CUST']) {
    final random = Random();
    final suffix =
        List.generate(8, (_) => _idAlphabet[random.nextInt(_idAlphabet.length)])
            .join();
    return '$prefix-$suffix';
  }

  Future<List<CustomerModel>> _activeCustomers() async {
    final all = await _localStorage.readAll();
    return all.where((customer) => !customer.isDeleted).toList();
  }

  bool _matchesSearch(
      CustomerModel customer, String search, List<String> purchasedProducts) {
    final needle = search.toLowerCase();
    return customer.fullName.toLowerCase().contains(needle) ||
        customer.phone.toLowerCase().contains(needle) ||
        (customer.email?.toLowerCase().contains(needle) ?? false) ||
        customer.id.toLowerCase().contains(needle) ||
        customer.tags.any((tag) => tag.toLowerCase().contains(needle)) ||
        purchasedProducts.any((name) => name.toLowerCase().contains(needle));
  }

  List<CustomerModel> _applyQuery(
    List<CustomerModel> customers,
    CustomerQuery query,
    Map<String, List<String>> productsByCustomer,
  ) {
    var result = customers;

    final search = query.search;
    if (search != null && search.isNotEmpty) {
      result = result
          .where((c) =>
              _matchesSearch(c, search, productsByCustomer[c.id] ?? const []))
          .toList();
    }

    result = switch (query.filter) {
      CustomerFilter.all => result,
      CustomerFilter.active =>
        result.where((c) => c.status == CustomerStatus.active).toList(),
      CustomerFilter.inactive =>
        result.where((c) => c.status == CustomerStatus.inactive).toList(),
      CustomerFilter.vip => result.where((c) => c.isVip).toList(),
      CustomerFilter.recentlyAdded => result,
      CustomerFilter.highestSpending => result,
    };

    result = [...result];
    switch (query.filter) {
      case CustomerFilter.highestSpending:
        result.sort((a, b) => b.lifetimeSpend.compareTo(a.lifetimeSpend));
      case CustomerFilter.all:
      case CustomerFilter.active:
      case CustomerFilter.inactive:
      case CustomerFilter.vip:
      case CustomerFilter.recentlyAdded:
        result.sort((a, b) => b.memberSince.compareTo(a.memberSince));
    }

    return result;
  }

  /// Only read when a search term is present — every other filter/browse
  /// path never touches purchase history at all.
  Future<Map<String, List<String>>> _productsByCustomer(String? search) async {
    if (search == null || search.isEmpty) return const {};
    final purchases = await _purchaseLocalStorage.readAll();
    final byCustomer = <String, List<String>>{};
    for (final purchase in purchases) {
      byCustomer
          .putIfAbsent(purchase.customerId, () => [])
          .addAll(purchase.items);
    }
    return byCustomer;
  }

  @override
  Future<CustomerPage> listCustomers(CustomerQuery query,
      {String? cursor, int limit = 20}) async {
    final productsByCustomer = await _productsByCustomer(query.search);
    final filtered =
        _applyQuery(await _activeCustomers(), query, productsByCustomer);
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, filtered.length);
    final items = start >= filtered.length
        ? const <CustomerModel>[]
        : filtered.sublist(start, end);
    final nextCursor = end < filtered.length ? '$end' : null;
    return CustomerPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<CustomerModel> getCustomer(String customerId) async {
    final all = await _activeCustomers();
    return all.firstWhere((c) => c.id == customerId,
        orElse: () => throw StateError('Customer not found.'));
  }

  @override
  Future<CustomerModel> createCustomer(CustomerDraft draft) async {
    final all = await _localStorage.readAll();
    final now = DateTime.now();
    final note = draft.initialNote?.trim();

    final customer = CustomerModel(
      id: _generateId(),
      firstName: draft.firstName,
      lastName: draft.lastName,
      phone: draft.phone,
      email: draft.email,
      dateOfBirth: draft.dateOfBirth,
      gender: draft.gender,
      address: draft.address,
      city: draft.city,
      postalCode: draft.postalCode,
      country: draft.country,
      company: draft.company,
      vatNumber: draft.vatNumber,
      notes: note == null || note.isEmpty
          ? const []
          : [CustomerNote(id: _generateId('NOTE'), text: note, createdAt: now)],
      tags: draft.tags,
      memberSince: now,
    );

    await _localStorage.writeAll([...all, customer]);
    return customer;
  }

  @override
  Future<CustomerModel> updateCustomer(
      String customerId, CustomerDraft draft) async {
    final all = await _localStorage.readAll();
    final index = all.indexWhere((c) => c.id == customerId);
    if (index == -1) throw StateError('Customer not found.');

    final updated = all[index].copyWith(
      firstName: draft.firstName,
      lastName: draft.lastName,
      phone: draft.phone,
      email: draft.email,
      clearEmail: draft.email == null,
      dateOfBirth: draft.dateOfBirth,
      clearDateOfBirth: draft.dateOfBirth == null,
      gender: draft.gender,
      clearGender: draft.gender == null,
      address: draft.address,
      clearAddress: draft.address == null,
      city: draft.city,
      clearCity: draft.city == null,
      postalCode: draft.postalCode,
      clearPostalCode: draft.postalCode == null,
      country: draft.country,
      clearCountry: draft.country == null,
      company: draft.company,
      clearCompany: draft.company == null,
      vatNumber: draft.vatNumber,
      clearVatNumber: draft.vatNumber == null,
      tags: draft.tags,
    );

    final next = [...all];
    next[index] = updated;
    await _localStorage.writeAll(next);
    return updated;
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    final all = await _localStorage.readAll();
    final index = all.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final next = [...all];
    next[index] = next[index].copyWith(isDeleted: true);
    await _localStorage.writeAll(next);
  }

  @override
  Future<CustomerModel> addNote(String customerId, String text) async {
    final all = await _localStorage.readAll();
    final index = all.indexWhere((c) => c.id == customerId);
    if (index == -1) throw StateError('Customer not found.');

    final note = CustomerNote(
        id: _generateId('NOTE'), text: text, createdAt: DateTime.now());
    final updated = all[index].copyWith(notes: [...all[index].notes, note]);

    final next = [...all];
    next[index] = updated;
    await _localStorage.writeAll(next);
    return updated;
  }

  @override
  Future<CustomerStats> getStats() async {
    final customers = await _activeCustomers();
    if (customers.isEmpty) return emptyCustomerStats;

    final now = DateTime.now();
    final newThisMonth = customers
        .where((c) =>
            c.memberSince.year == now.year && c.memberSince.month == now.month)
        .length;
    final activeCustomers =
        customers.where((c) => c.status == CustomerStatus.active).length;
    final vipCustomers = customers.where((c) => c.isVip).length;
    final totalSpend =
        customers.fold<double>(0, (sum, c) => sum + c.lifetimeSpend);
    final totalOrders = customers.fold<int>(0, (sum, c) => sum + c.totalOrders);

    var returningCustomers = 0;
    var inactiveCustomers = 0;
    for (final customer in customers) {
      final segments = computeCustomerSegments(customer, now: now);
      if (segments.contains(CustomerSegment.returning)) returningCustomers++;
      if (segments.contains(CustomerSegment.inactive)) inactiveCustomers++;
    }

    return (
      totalCustomers: customers.length,
      newThisMonth: newThisMonth,
      activeCustomers: activeCustomers,
      vipCustomers: vipCustomers,
      averageSpend: totalSpend / customers.length,
      averageOrders: totalOrders / customers.length,
      returningCustomers: returningCustomers,
      inactiveCustomers: inactiveCustomers,
      lifetimeRevenue: totalSpend,
    );
  }

  @override
  Future<List<CustomerPurchase>> getPurchaseHistory(String customerId,
      {String? cursor, int limit = 20}) async {
    final all = await _purchaseLocalStorage.readAll();
    final forCustomer = all.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, forCustomer.length);
    return start >= forCustomer.length
        ? const []
        : forCustomer.sublist(start, end);
  }

  @override
  Future<CustomerModel> recordPurchase(
    String customerId, {
    required double amount,
    required List<String> itemNames,
    required String paymentMethod,
    required DateTime purchasedAt,
    String? receiptNumber,
  }) async {
    final all = await _localStorage.readAll();
    final index = all.indexWhere((c) => c.id == customerId);
    if (index == -1) throw StateError('Customer not found.');

    final pointsEarned = pointsEarnedForAmount(amount);
    final updated = all[index].copyWith(
      lifetimeSpend: all[index].lifetimeSpend + amount,
      totalOrders: all[index].totalOrders + 1,
      lastPurchaseAt: purchasedAt,
      loyaltyPoints: all[index].loyaltyPoints + pointsEarned,
      lifetimePoints: all[index].lifetimePoints + pointsEarned,
    );

    final next = [...all];
    next[index] = updated;
    await _localStorage.writeAll(next);

    final purchases = await _purchaseLocalStorage.readAll();
    await _purchaseLocalStorage.writeAll([
      ...purchases,
      CustomerPurchase(
        customerId: customerId,
        receiptNumber: receiptNumber ?? _generateId('RCPT'),
        date: purchasedAt,
        items: itemNames,
        total: amount,
        paymentMethod: paymentMethod,
        status: PurchaseStatus.completed,
      ),
    ]);

    return updated;
  }

  @override
  Future<List<({String name, int timesPurchased})>> getFavoriteProducts(
      String customerId,
      {int limit = 5}) async {
    final purchases = await getPurchaseHistory(customerId, limit: 1 << 30);
    final counts = <String, int>{};
    for (final purchase in purchases) {
      for (final item in purchase.items) {
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((entry) => (name: entry.key, timesPurchased: entry.value))
        .toList();
  }
}
