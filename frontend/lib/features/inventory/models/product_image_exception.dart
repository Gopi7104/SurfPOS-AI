/// A Product Image pick/capture failure — the message is already
/// human-readable (crafted in [InventoryRepositoryImpl], not relayed from a
/// backend), so callers can show [message] directly, mirroring how
/// [ApiException.message] is used elsewhere.
class ProductImageException implements Exception {
  const ProductImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
