import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../models/sales_ledger_snapshot.dart';
import '../models/sales_record.dart';
import '../repositories/sales_ledger_local_storage.dart';
import '../repositories/sales_ledger_repository.dart';
import '../repositories/sales_ledger_repository_impl.dart';

/// DI wiring for the real sales ledger (Phase CRM-2) — mirrors
/// `customerPurchaseLocalStorageProvider`/`customerRepositoryProvider`'s own
/// `.family`-by-uid shape exactly, for the same reason (the local-storage
/// key embeds the uid, only known at read time).
final salesLedgerLocalStorageProvider =
    Provider.family<SalesLedgerLocalStorage, String>((ref, uid) {
  return SalesLedgerLocalStorage(ref.watch(secureStorageServiceProvider), uid);
});

final salesLedgerRepositoryProvider =
    Provider.family<SalesLedgerRepository, String>((ref, uid) {
  return SalesLedgerRepositoryImpl(
      localStorage: ref.watch(salesLedgerLocalStorageProvider(uid)));
});

/// Every recorded sale for this merchant — watched by both Dashboard (via
/// [salesLedgerSnapshotProvider]) and indirectly by Reports (via its own
/// repository read). `autoDispose` so a previous user's ledger is never
/// held onto; Payments' success hook invalidates this the moment a new
/// sale is recorded, which is what makes Dashboard/Reports update live
/// the instant a payment completes instead of only on next app open.
final salesLedgerRecordsProvider =
    FutureProvider.autoDispose.family<List<SalesRecord>, String>((ref, uid) {
  return ref.watch(salesLedgerRepositoryProvider(uid)).getAll();
});

/// Dashboard's real "today" figures — `null` until at least one real sale
/// has ever been recorded, so [DashboardPage] can keep falling back to
/// [DemoDataController] exactly as before until then (see
/// `DashboardPage`'s own header comment).
final salesLedgerSnapshotProvider = FutureProvider.autoDispose
    .family<SalesLedgerSnapshot?, String>((ref, uid) async {
  final records = await ref.watch(salesLedgerRecordsProvider(uid).future);
  if (records.isEmpty) return null;
  return SalesLedgerSnapshot(records);
});
