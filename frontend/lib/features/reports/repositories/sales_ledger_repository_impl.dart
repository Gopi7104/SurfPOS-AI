import '../models/sales_record.dart';
import 'sales_ledger_local_storage.dart';
import 'sales_ledger_repository.dart';

class SalesLedgerRepositoryImpl implements SalesLedgerRepository {
  SalesLedgerRepositoryImpl({required SalesLedgerLocalStorage localStorage})
      : _localStorage = localStorage;

  final SalesLedgerLocalStorage _localStorage;

  @override
  Future<void> recordSale(SalesRecord record) async {
    final all = await _localStorage.readAll();
    await _localStorage.writeAll([...all, record]);
  }

  @override
  Future<List<SalesRecord>> getAll() => _localStorage.readAll();
}
