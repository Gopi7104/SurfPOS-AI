import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/reports/models/sales_record.dart';
import 'package:surfpos_ai/features/reports/repositories/sales_ledger_api_storage.dart';
import 'package:surfpos_ai/features/reports/repositories/sales_ledger_repository_impl.dart';

/// In-memory double for the Firebase-backed API storage class — no real
/// HTTP call involved, same "implements the concrete class, override just
/// its public readAll/writeAll" pattern `product_image_local_storage_test.dart`
/// already uses for [SecureStorageService].
class _FakeSalesLedgerApiStorage implements SalesLedgerApiStorage {
  List<SalesRecord> _items = [];

  @override
  Future<List<SalesRecord>> readAll() async => _items;

  @override
  Future<void> writeAll(List<SalesRecord> records) async {
    _items = records;
  }
}

SalesLedgerRepositoryImpl _repository() {
  return SalesLedgerRepositoryImpl(localStorage: _FakeSalesLedgerApiStorage());
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
