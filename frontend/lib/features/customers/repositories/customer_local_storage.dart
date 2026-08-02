import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../models/customer_model.dart';

/// The whole customer list, as one JSON blob under one key in
/// [SecureStorageService] — mirrors `ProductImageLocalStorage`/
/// `MerchantOnboardingLocalStorage`'s read-modify-write-the-whole-map(list)
/// shape. Scoped to a single Firebase [uid] (the key embeds it) so
/// Merchant B signing in right after Merchant A can never read Merchant
/// A's customers back out of shared storage — same cross-user isolation
/// rule every other local cache in this app follows.
class CustomerLocalStorage {
  CustomerLocalStorage(this._storage, this.uid);

  final SecureStorageService _storage;
  final String uid;

  String get _key => 'customers.customerList.$uid';

  Future<List<CustomerModel>> readAll() async {
    final raw = await _storage.read(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => CustomerModel.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<CustomerModel> customers) {
    return _storage.write(
      _key,
      jsonEncode(customers.map((customer) => customer.toJson()).toList()),
    );
  }
}
