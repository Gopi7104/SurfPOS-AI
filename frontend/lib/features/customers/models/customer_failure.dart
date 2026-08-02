/// User-facing failure message for any Customers operation — never
/// surfaces raw exception types/stack traces to the UI, mirroring
/// `InventoryFailure`. Local-storage errors have no structured
/// `ApiException` to relay a message from (there's no backend yet), so
/// this is always the generic fallback.
class CustomerFailure {
  const CustomerFailure(this.message);

  final String message;

  factory CustomerFailure.fromException(Object error) {
    return const CustomerFailure('Something went wrong. Please try again.');
  }
}
