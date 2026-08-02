/// User-facing failure message for any Settings operation — mirrors
/// `CustomerFailure`/`InventoryFailure`. Local-storage errors have no
/// structured `ApiException` to relay a message from, so this is always
/// the generic fallback.
class SettingsFailure {
  const SettingsFailure(this.message);

  final String message;

  factory SettingsFailure.fromException(Object error) {
    return const SettingsFailure('Something went wrong. Please try again.');
  }
}
