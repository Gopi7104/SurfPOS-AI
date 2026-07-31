import '../../../core/exceptions/api_exception.dart';

/// User-facing failure message for any Payment operation — never surfaces
/// raw exception types/stack traces to the UI (see docs/07_CODING_RULES.md
/// § 14), mirroring `BillingFailure`/`InventoryFailure`.
class PaymentFailure {
  const PaymentFailure(this.message);

  final String message;

  /// Backend [ApiException] messages are relayed verbatim — the backend
  /// already writes human-readable copy (including Surfboard's own message,
  /// per docs/15_SURFBOARD_INTEGRATION.md's error-mapping convention).
  factory PaymentFailure.fromException(Object error) {
    if (error is ApiException) {
      return PaymentFailure(error.message);
    }
    return const PaymentFailure('Something went wrong. Please try again.');
  }
}
