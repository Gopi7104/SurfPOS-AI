import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_lookup_exception.dart';
import '../models/product_lookup_state.dart';
import '../providers/inventory_providers.dart';
import '../repositories/product_lookup_repository.dart';

/// Barcode-lookup state for exactly one Firebase uid (see
/// [productLookupControllerProvider] — a `.family` provider) — never a
/// global singleton, mirroring every other controller in this app.
///
/// A plain [Notifier], not an [AsyncNotifier] — mirrors [BillingController]:
/// only [lookup] itself is async; it updates its own slice of
/// [ProductLookupState] rather than wrapping the whole notifier state.
class ProductLookupController
    extends AutoDisposeFamilyNotifier<ProductLookupState, String> {
  @override
  ProductLookupState build(String uid) => const ProductLookupState();

  /// The barcode scanner decoded a code — resolve it against Inventory
  /// first, then external providers (see [ProductLookupRepository]), and
  /// update exactly one of [ProductLookupState]'s result slots.
  Future<void> lookup(String barcode) async {
    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearExistingProduct: true,
      clearNotFoundBarcode: true,
      clearErrorMessage: true,
    );
    try {
      final outcome =
          await ref.read(productLookupRepositoryProvider).lookup(barcode);
      switch (outcome) {
        case ProductLookupExisting(:final product):
          state = state.copyWith(isLoading: false, existingProduct: product);
        case ProductLookupFound(:final result):
          state = state.copyWith(isLoading: false, result: result);
        case ProductLookupNotFound():
          state = state.copyWith(isLoading: false, notFoundBarcode: barcode);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ProductLookupFailure.fromException(error).message,
      );
    }
  }

  /// Clears any settled result so the scanner can resume — "Try Again"/
  /// "Scan Again"/after navigating away to Add Product.
  void reset() => state = const ProductLookupState();
}
