import 'product_lookup_result.dart';
import 'product_model.dart';

/// [ProductLookupController]'s state — a plain (non-`AsyncValue`) state,
/// mirroring `BillingState`: [isLoading] covers the one in-flight lookup,
/// and exactly one of [result]/[existingProduct]/[notFoundBarcode]/
/// [errorMessage] is set once it resolves.
class ProductLookupState {
  const ProductLookupState({
    this.isLoading = false,
    this.result,
    this.existingProduct,
    this.notFoundBarcode,
    this.errorMessage,
  });

  final bool isLoading;

  /// Set when an external provider (Open Food Facts, ...) had a record for
  /// the scanned barcode — the UI navigates to Add Product prefilled with
  /// this once set.
  final ProductLookupResult? result;

  /// Set when the scanned barcode already belongs to a product in this
  /// merchant's own Inventory — no provider was called.
  final ProductModel? existingProduct;

  /// Set when neither Inventory nor any provider has a record for this
  /// barcode — the UI shows "Product not found in product database." with
  /// "Enter Manually"/"Try Again".
  final String? notFoundBarcode;

  /// Set when the lookup itself failed (network/timeout/invalid barcode).
  final String? errorMessage;

  ProductLookupState copyWith({
    bool? isLoading,
    ProductLookupResult? result,
    bool clearResult = false,
    ProductModel? existingProduct,
    bool clearExistingProduct = false,
    String? notFoundBarcode,
    bool clearNotFoundBarcode = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ProductLookupState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      existingProduct: clearExistingProduct
          ? null
          : (existingProduct ?? this.existingProduct),
      notFoundBarcode: clearNotFoundBarcode
          ? null
          : (notFoundBarcode ?? this.notFoundBarcode),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
