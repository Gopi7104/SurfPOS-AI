import '../../../core/exceptions/api_exception.dart';

/// User-facing failure message for any Inventory operation — never surfaces
/// raw exception types/stack traces to the UI (see
/// docs/07_CODING_RULES.md § 14), mirroring `MerchantOnboardingFailure`.
class InventoryFailure {
  const InventoryFailure(this.message);

  final String message;

  /// Backend [ApiException] messages are relayed verbatim — the backend
  /// already writes human-readable copy (e.g. "A product with this SKU
  /// already exists" for a [ConflictException]).
  factory InventoryFailure.fromException(Object error) {
    if (error is ApiException) {
      return InventoryFailure(error.message);
    }
    return const InventoryFailure('Something went wrong. Please try again.');
  }
}
