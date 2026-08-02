import '../models/sales_record.dart';

/// Seam between Payments' success hook and wherever the sales ledger
/// actually lives — local-storage-only for now (see
/// [SalesLedgerLocalStorage]'s header comment), mirroring
/// `CustomerRepository`'s role for the Customers feature.
abstract class SalesLedgerRepository {
  /// Called once per completed sale (real Surfboard checkout or a Test
  /// Payment), right when payment succeeds — the one and only write path
  /// for the ledger. Never called from within Reports/Dashboard
  /// themselves.
  Future<void> recordSale(SalesRecord record);

  /// Every recorded sale, oldest first — Reports/Dashboard derive every
  /// revenue/order/product/category figure from this in memory (see
  /// `SalesLedgerSnapshot`), the same small-scale-app assumption
  /// `CustomerRepositoryImpl` already makes for customers/purchases.
  Future<List<SalesRecord>> getAll();
}
