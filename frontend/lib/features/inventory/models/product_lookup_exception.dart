/// Typed failures a [ProductLookupDatasource] can throw. Deliberately
/// separate from [ApiException] (`core/exceptions/api_exception.dart`):
/// that hierarchy mirrors *this app's own backend* error envelope
/// (`{success:false, error:{code,message}}`) — Open Food Facts (and any
/// future provider) is a third-party API with no such envelope, so it gets
/// its own small, provider-agnostic set of failure cases instead.
sealed class ProductLookupException implements Exception {
  const ProductLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No response reached us at all — no connectivity, DNS failure, connection
/// refused.
class LookupNetworkException extends ProductLookupException {
  const LookupNetworkException()
      : super(
          'Could not reach the product database. Check your internet '
          'connection and try again.',
        );
}

/// The request was sent but timed out waiting for a response.
class LookupTimeoutException extends ProductLookupException {
  const LookupTimeoutException()
      : super('The product lookup timed out. Please try again.');
}

/// The scanned code isn't shaped like a retail barcode (EAN/UPC/GTIN) —
/// caught before any network call is made.
class InvalidBarcodeException extends ProductLookupException {
  const InvalidBarcodeException()
      : super('That doesn\'t look like a valid product barcode.');
}

/// Anything else — an unexpected response shape, a non-timeout HTTP error,
/// etc.
class LookupUnknownException extends ProductLookupException {
  const LookupUnknownException([String? message])
      : super(
          message ??
              'Something went wrong looking up this product. Please try again.',
        );
}

/// User-facing failure message for a barcode lookup — never surfaces raw
/// exception types/stack traces to the UI (see docs/07_CODING_RULES.md
/// § 14), mirroring `InventoryFailure`/`BillingFailure`.
class ProductLookupFailure {
  const ProductLookupFailure(this.message);

  final String message;

  factory ProductLookupFailure.fromException(Object error) {
    if (error is ProductLookupException) {
      return ProductLookupFailure(error.message);
    }
    return const ProductLookupFailure(
        'Something went wrong. Please try again.');
  }
}
