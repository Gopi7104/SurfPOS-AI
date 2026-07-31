import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/models/product_model.dart';
import '../models/billing_failure.dart';
import '../models/billing_state.dart';
import '../models/cart_item_model.dart';
import '../providers/billing_providers.dart';

/// Cart + product-lookup state for exactly one Firebase uid (see
/// [billingControllerProvider] — a `.family` provider, the uid is this
/// notifier's `arg`) — never a global singleton, so one merchant's
/// in-progress sale can never be observed under another account's session,
/// even transiently (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user
/// isolation fix — the same pattern every controller in this app follows).
///
/// A plain [Notifier], not an [AsyncNotifier]: the cart itself is always
/// synchronously available (nothing to "load" on `build()`), so wrapping
/// the whole state in `AsyncValue` would force every cart mutation through
/// a loading state it doesn't need. Only [search]/[addProductByBarcode]
/// are async, and they update their own slice of [BillingState] rather than
/// the whole notifier state.
class BillingController
    extends AutoDisposeFamilyNotifier<BillingState, String> {
  @override
  BillingState build(String uid) => const BillingState();

  /// Debounced by the caller (the search field's `onChanged`, mirroring
  /// `ProductListPage`'s own debounce) — this method itself fires one
  /// lookup per call, no internal timer.
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, clearSearchError: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    try {
      final results =
          await ref.read(billingRepositoryProvider).searchProducts(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (error) {
      state = state.copyWith(
        isSearching: false,
        searchResults: const [],
        searchError: BillingFailure.fromException(error).message,
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
        searchQuery: '',
        searchResults: const [],
        isSearching: false,
        clearSearchError: true);
  }

  /// A search suggestion was tapped — add it and collapse the suggestions
  /// list back to the cart view.
  void selectSearchResult(ProductModel product) {
    _addOrIncrement(product);
    state = state.copyWith(
      searchQuery: '',
      searchResults: const [],
      clearSearchError: true,
      lastAddedProductName: product.name,
    );
  }

  /// The barcode scanner decoded a code — look it up and either add it
  /// (incrementing if already in the cart) or surface "not found".
  Future<void> addProductByBarcode(String barcode) async {
    state = state.copyWith(
        clearNotFoundBarcode: true, clearLastAddedProductName: true);
    try {
      final product = await ref
          .read(billingRepositoryProvider)
          .findProductByBarcode(barcode);
      if (product == null) {
        state = state.copyWith(notFoundBarcode: barcode);
        return;
      }
      _addOrIncrement(product);
      state = state.copyWith(lastAddedProductName: product.name);
    } catch (error) {
      state = state.copyWith(
          searchError: BillingFailure.fromException(error).message);
    }
  }

  void _addOrIncrement(ProductModel product) {
    final index =
        state.items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = state.copyWith(items: [
        ...state.items,
        CartItemModel(product: product, quantity: 1)
      ]);
      return;
    }
    final updated = [...state.items];
    updated[index] =
        updated[index].copyWith(quantity: updated[index].quantity + 1);
    state = state.copyWith(items: updated);
  }

  void increaseQuantity(String productId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId)
            item.copyWith(quantity: item.quantity + 1)
          else
            item,
      ],
    );
  }

  /// A no-op below quantity 1 — use [removeItem] to delete the row entirely.
  void decreaseQuantity(String productId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId && item.quantity > 1)
            item.copyWith(quantity: item.quantity - 1)
          else
            item,
      ],
    );
  }

  void removeItem(String productId) {
    state = state.copyWith(
        items:
            state.items.where((item) => item.product.id != productId).toList());
  }

  void clearCart() {
    state = state.copyWith(items: const []);
  }

  void dismissNotFound() => state = state.copyWith(clearNotFoundBarcode: true);

  void dismissLastAdded() =>
      state = state.copyWith(clearLastAddedProductName: true);
}
