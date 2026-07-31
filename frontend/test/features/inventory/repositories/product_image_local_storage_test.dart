import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/inventory/repositories/product_image_local_storage.dart';

/// In-memory [SecureStorageService] double — no platform channel involved.
class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

void main() {
  test('set()/get() round-trip a path for a product id', () async {
    final storage = ProductImageLocalStorage(_FakeSecureStorageService());

    await storage.set('prod-1', '/data/images/wax.jpg');

    expect(await storage.get('prod-1'), '/data/images/wax.jpg');
    expect(await storage.get('prod-2'), isNull);
  });

  test('set() with null clears a previously stored path', () async {
    final storage = ProductImageLocalStorage(_FakeSecureStorageService());
    await storage.set('prod-1', '/data/images/wax.jpg');

    await storage.set('prod-1', null);

    expect(await storage.get('prod-1'), isNull);
  });

  test('remove() clears the path for one product without affecting others',
      () async {
    final storage = ProductImageLocalStorage(_FakeSecureStorageService());
    await storage.set('prod-1', '/data/images/a.jpg');
    await storage.set('prod-2', '/data/images/b.jpg');

    await storage.remove('prod-1');

    expect(await storage.get('prod-1'), isNull);
    expect(await storage.get('prod-2'), '/data/images/b.jpg');
  });

  test('getMany() batch-looks-up only the requested ids', () async {
    final storage = ProductImageLocalStorage(_FakeSecureStorageService());
    await storage.set('prod-1', '/data/images/a.jpg');
    await storage.set('prod-2', '/data/images/b.jpg');
    await storage.set('prod-3', '/data/images/c.jpg');

    final result = await storage.getMany(['prod-1', 'prod-3', 'prod-missing']);

    expect(result,
        {'prod-1': '/data/images/a.jpg', 'prod-3': '/data/images/c.jpg'});
  });
}
