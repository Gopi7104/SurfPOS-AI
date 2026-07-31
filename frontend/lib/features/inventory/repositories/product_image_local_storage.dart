import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';

/// Maps `productId -> local device image file path` — the only place this
/// association is persisted, since the backend has no column for it (cloud
/// image storage is a later phase; see `docs/22_DEVELOPMENT_ROADMAP.md`).
/// Mirrors `MerchantOnboardingLocalStorage`'s shape: a single JSON blob
/// under one key in [SecureStorageService], read-modify-written as a whole
/// map (the target catalog size makes this simplification fine, same
/// rationale as `product.repository.js`'s in-memory filtering).
class ProductImageLocalStorage {
  ProductImageLocalStorage(this._storage);

  final SecureStorageService _storage;

  static const _key = 'inventory.productImagePaths';

  Future<Map<String, String>> _readAll() async {
    final raw = await _storage.read(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _writeAll(Map<String, String> all) {
    return _storage.write(_key, jsonEncode(all));
  }

  Future<String?> get(String productId) async => (await _readAll())[productId];

  /// Batch lookup for a page of products — one storage read instead of one
  /// per product.
  Future<Map<String, String>> getMany(Iterable<String> productIds) async {
    final all = await _readAll();
    final ids = productIds.toSet();
    return {
      for (final entry in all.entries)
        if (ids.contains(entry.key)) entry.key: entry.value,
    };
  }

  /// `imagePath: null` removes the entry (equivalent to [remove]).
  Future<void> set(String productId, String? imagePath) async {
    final all = await _readAll();
    if (imagePath == null) {
      all.remove(productId);
    } else {
      all[productId] = imagePath;
    }
    await _writeAll(all);
  }

  Future<void> remove(String productId) => set(productId, null);
}
