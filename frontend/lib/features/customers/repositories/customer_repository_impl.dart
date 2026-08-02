import 'dart:math';

import '../models/customer_draft.dart';
import '../models/customer_model.dart';
import '../models/customer_note.dart';
import '../models/customer_page.dart';
import '../models/customer_purchase.dart';
import '../models/customer_query.dart';
import '../models/customer_stats.dart';
import '../models/customer_status.dart';
import 'customer_local_storage.dart';
import 'customer_repository.dart';

/// Reads/writes the whole customer list via [CustomerLocalStorage] — no
/// `/customers` backend endpoint exists yet (Phase 6 scope: "use local
/// storage for now"). Every write is read-modify-write-the-whole-list,
/// same simplification `ProductImageLocalStorage`/product filtering
/// already use for this app's target small-retailer scale.
///
/// [getPurchaseHistory] always returns empty: this app has no persisted
/// Sale/order history anywhere yet (confirmed while building Reports —
/// `ReceiptModel` is built client-side and discarded once shown, and
/// `webhook.controller.js` documents the same gap), and this module must
/// not touch Billing/Payments/Receipt to add one. [CustomerModel]'s
/// lifetime stats (spend/orders/points) stay at their create-time zero for
/// the same reason — genuinely empty, not a bug, until a purchase-history
/// persistence layer exists somewhere in this app for this module to read.
class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl({required CustomerLocalStorage localStorage})
      : _localStorage = localStorage;

  final CustomerLocalStorage _localStorage;

  static const _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  String _generateId() {
    final random = Random();
    final suffix =
        List.generate(8, (_) => _idAlphabet[random.nextInt(_idAlphabet.length)])
            .join();
    return 'CUST-$suffix';
  }

  Future<List<CustomerModel>> _activeCustomers() async {
    final all = await _localStorage.readAll();
    return all.where((customer) => !customer.isDeleted).toList();
  }

  bool _matchesSearch(CustomerModel customer, String search) {
    final needle = search.toLowerCase();
    return customer.fullName.toLowerCase().contains(needle) ||
        customer.phone.toLowerCase().contains(needle) ||
        (customer.email?.toLowerCase().contains(needle) ?? false) ||
        customer.id.toLowerCase().contains(needle);
  }

  List<CustomerModel> _applyQuery(
      List<CustomerModel> customers, CustomerQuery query) {
    var result = customers;

    final search = query.search;
    if (search != null && search.isNotEmpty) {
      result = result.where((c) => _matchesSearch(c, search)).toList();
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

  @override
  Future<CustomerPage> listCustomers(CustomerQuery query,
      {String? cursor, int limit = 20}) async {
    final filtered = _applyQuery(await _activeCustomers(), query);
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
          : [CustomerNote(id: _generateId(), text: note, createdAt: now)],
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

    final note =
        CustomerNote(id: _generateId(), text: text, createdAt: DateTime.now());
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

    return (
      totalCustomers: customers.length,
      newThisMonth: newThisMonth,
      activeCustomers: activeCustomers,
      vipCustomers: vipCustomers,
      averageSpend: totalSpend / customers.length,
      averageOrders: totalOrders / customers.length,
    );
  }

  @override
  Future<List<CustomerPurchase>> getPurchaseHistory(String customerId,
      {String? cursor, int limit = 20}) async {
    return const [];
  }
}
