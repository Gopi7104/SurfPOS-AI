import '../../../core/exceptions/api_exception.dart';

/// User-facing failure message for any Billing operation (product search,
/// barcode lookup) — never surfaces raw exception types/stack traces to the
/// UI (see docs/07_CODING_RULES.md § 14), mirroring `InventoryFailure`.
class BillingFailure {
  const BillingFailure(this.message);

  final String message;

  /// Backend [ApiException] messages are relayed verbatim — the backend
  /// already writes human-readable copy. A network failure while looking up
  /// a product ("Inventory unavailable") falls out of [NetworkException]'s
  /// own message naturally.
  factory BillingFailure.fromException(Object error) {
    if (error is ApiException) {
      return BillingFailure(error.message);
    }
    return const BillingFailure('Something went wrong. Please try again.');
  }
}
