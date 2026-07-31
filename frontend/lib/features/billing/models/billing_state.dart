import '../../inventory/models/product_model.dart';
import 'cart_item_model.dart';

/// [BillingController]'s state — the cart itself, plus the transient
/// search/scan sub-states the Billing screen renders around it. Unlike
/// Inventory's controllers, this is a plain (non-`AsyncValue`) state: the
/// cart is always synchronously available (there's nothing to "load"), only
/// the search/barcode-lookup sub-operations are async, and they update
/// their own slice of this state rather than wrapping the whole cart in a
/// loading/error wrapper.
class BillingState {
  const BillingState({
    this.items = const [],
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
    this.notFoundBarcode,
    this.lastAddedProductName,
  });

  final List<CartItemModel> items;

  final String searchQuery;
  final List<ProductModel> searchResults;
  final bool isSearching;
  final String? searchError;

  /// Set when a scanned/looked-up barcode matches no active product — the
  /// UI shows "Product not found." plus "Search manually" / "Add Product"
  /// actions until this is dismissed.
  final String? notFoundBarcode;

  /// Set right after a product is added/incremented (via search selection
  /// or barcode scan) so the UI can show a one-off "✓ Product Added"
  /// confirmation, then dismissed.
  final String? lastAddedProductName;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineSubtotal);

  double get discountTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineDiscount);

  double get taxTotal => items.fold(0.0, (sum, item) => sum + item.lineTax);

  double get grandTotal => subtotal - discountTotal + taxTotal;

  BillingState copyWith({
    List<CartItemModel>? items,
    String? searchQuery,
    List<ProductModel>? searchResults,
    bool? isSearching,
    String? searchError,
    bool clearSearchError = false,
    String? notFoundBarcode,
    bool clearNotFoundBarcode = false,
    String? lastAddedProductName,
    bool clearLastAddedProductName = false,
  }) {
    return BillingState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      notFoundBarcode: clearNotFoundBarcode
          ? null
          : (notFoundBarcode ?? this.notFoundBarcode),
      lastAddedProductName: clearLastAddedProductName
          ? null
          : (lastAddedProductName ?? this.lastAddedProductName),
    );
  }
}
