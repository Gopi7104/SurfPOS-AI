import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../models/sales_record.dart';

/// The whole sales ledger, as one JSON blob under one key in
/// [SecureStorageService] — mirrors `CustomerPurchaseLocalStorage`'s
/// read-modify-write-the-whole-list shape exactly. Scoped to a single
/// Firebase [uid], same cross-user isolation rule every other local cache
/// in this app follows.
class SalesLedgerLocalStorage {
  SalesLedgerLocalStorage(this._storage, this.uid);

  final SecureStorageService _storage;
  final String uid;

  String get _key => 'reports.salesLedger.$uid';

  Future<List<SalesRecord>> readAll() async {
    final raw = await _storage.read(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => SalesRecord.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<SalesRecord> records) {
    return _storage.write(
      _key,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}
