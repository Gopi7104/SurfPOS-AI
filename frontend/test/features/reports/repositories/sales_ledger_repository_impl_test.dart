import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/reports/models/sales_record.dart';
import 'package:surfpos_ai/features/reports/repositories/sales_ledger_local_storage.dart';
import 'package:surfpos_ai/features/reports/repositories/sales_ledger_repository_impl.dart';

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

const _uid = 'uid-1';

SalesLedgerRepositoryImpl _repository() {
  final storage = _FakeSecureStorageService();
  return SalesLedgerRepositoryImpl(
      localStorage: SalesLedgerLocalStorage(storage, _uid));
}

void main() {
  test('getAll() is empty before any sale has ever been recorded', () async {
    expect(await _repository().getAll(), isEmpty);
  });

  test('recordSale() persists a sale, round-tripping every field', () async {
    final repository = _repository();
    final record = SalesRecord(
      id: 'sale-1',
      receiptNumber: 'R-1',
      occurredAt: DateTime(2026, 6, 1, 10),
      total: 42.5,
      paymentMethod: 'CARD',
      customerId: 'CUST-1',
      customerName: 'Alex Rivera',
      items: const [
        SalesRecordItem(
          productId: 'p1',
          name: 'Wax',
          category: 'Accessories',
          quantity: 2,
          unitPrice: 20,
          lineTotal: 40,
        ),
      ],
    );

    await repository.recordSale(record);
    final all = await repository.getAll();

    expect(all, hasLength(1));
    expect(all.single.id, 'sale-1');
    expect(all.single.total, 42.5);
    expect(all.single.customerId, 'CUST-1');
    expect(all.single.items.single.name, 'Wax');
    expect(all.single.items.single.category, 'Accessories');
  });

  test('recordSale() appends without overwriting previous sales', () async {
    final repository = _repository();
    await repository.recordSale(SalesRecord(
      id: 'sale-1',
      receiptNumber: 'R-1',
      occurredAt: DateTime(2026, 6, 1),
      total: 10,
      paymentMethod: 'CASH',
      items: const [],
    ));
    await repository.recordSale(SalesRecord(
      id: 'sale-2',
      receiptNumber: 'R-2',
      occurredAt: DateTime(2026, 6, 2),
      total: 20,
      paymentMethod: 'CARD',
      items: const [],
    ));

    final all = await repository.getAll();
    expect(all.map((r) => r.id), ['sale-1', 'sale-2']);
  });

  test('a sale with no customer/items round-trips with null/empty fields',
      () async {
    final repository = _repository();
    await repository.recordSale(SalesRecord(
      id: 'sale-1',
      receiptNumber: 'R-1',
      occurredAt: DateTime(2026, 6, 1),
      total: 15,
      paymentMethod: 'CASH',
      items: const [],
    ));

    final saved = (await repository.getAll()).single;
    expect(saved.customerId, isNull);
    expect(saved.customerName, isNull);
    expect(saved.items, isEmpty);
  });
}
