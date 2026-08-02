import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../models/customer_purchase.dart';

/// The whole purchase-history list (across every customer), as one JSON
/// blob under one key in [SecureStorageService] — mirrors
/// [CustomerLocalStorage]'s read-modify-write-the-whole-list shape exactly.
/// A flat list (each record carries its own `customerId`) rather than a
/// per-customer key, since this app's scale doesn't need per-customer
/// pagination at the storage layer — `CustomerRepositoryImpl` filters by
/// `customerId` in memory, same as it already does for search/filter over
/// the customer list itself. Scoped to a single Firebase [uid], same
/// cross-user isolation rule every other local cache in this app follows.
class CustomerPurchaseLocalStorage {
  CustomerPurchaseLocalStorage(this._storage, this.uid);

  final SecureStorageService _storage;
  final String uid;

  String get _key => 'customers.purchaseHistory.$uid';

  Future<List<CustomerPurchase>> readAll() async {
    final raw = await _storage.read(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
            (entry) => CustomerPurchase.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<CustomerPurchase> purchases) {
    return _storage.write(
      _key,
      jsonEncode(purchases.map((purchase) => purchase.toJson()).toList()),
    );
  }
}
