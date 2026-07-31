import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_draft.dart';
import '../models/product_model.dart';
import '../providers/inventory_providers.dart';

/// Add/Edit Product form submission state for exactly one Firebase uid (see
/// [inventoryFormControllerProvider] — a `.family` provider) — never a
/// global singleton, mirroring every other controller in this app (see
/// docs/22_DEVELOPMENT_ROADMAP.md, cross-user isolation fix). `null` until
/// [create]/[update] succeeds; the wizard screens navigate away on success
/// rather than rendering this state directly.
class InventoryFormController
    extends AutoDisposeFamilyAsyncNotifier<ProductModel?, String> {
  @override
  Future<ProductModel?> build(String uid) async => null;

  /// A no-op while a previous call is still in flight — the Save button is
  /// disabled by `state.isLoading` anyway, but guarding here too means a
  /// double-tap that lands before the rebuild can't race a second call
  /// through, mirroring `MerchantOnboardingController.submit()`.
  Future<void> create(ProductDraft draft,
      {int? initialStock, String? storeId}) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).createProduct(
            draft,
            initialStock: initialStock,
            storeId: storeId,
          ),
    );
  }

  /// [stockDelta]/[storeId] let Edit Product also change stock in the same
  /// submit — `PATCH .../:id` never touches stock itself (it lives in a
  /// separate per-store record), so a non-zero delta triggers a second
  /// `adjustStock` call, mirroring [create]'s `initialStock` composition.
  ///
  /// Named `updateProduct`, not `update` — `AsyncNotifierBase` already
  /// declares an `update()` method (its own state-mutation helper), and
  /// shadowing it with an incompatible signature is a compile error.
  Future<void> updateProduct(String productId, ProductDraft draft,
      {int? stockDelta, String? storeId}) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(inventoryRepositoryProvider);
      final updated = await repository.updateProduct(productId, draft);
      if (stockDelta != null && stockDelta != 0 && storeId != null) {
        await repository.adjustStock(productId,
            storeId: storeId, quantityDelta: stockDelta);
        return repository.getProduct(productId);
      }
      return updated;
    });
  }

  /// Opens the gallery picker and returns the picked file's local path, or
  /// `null` if the user cancelled. Never called directly by any widget —
  /// [ProductImagePicker] is the only caller — so `image_picker` itself
  /// stays entirely behind the repository/controller seam. Throws
  /// [ProductImageException] on a real failure (permission denied, missing
  /// file, etc.); the caller decides how to surface that.
  Future<String?> pickFromGallery() {
    return ref.read(inventoryRepositoryProvider).pickImageFromGallery();
  }

  /// Same contract as [pickFromGallery], via the device camera.
  Future<String?> takePhoto() {
    return ref.read(inventoryRepositoryProvider).captureImageFromCamera();
  }

  /// Clears the currently selected image. Kept as an async method (always
  /// resolving to `null`) purely so [ProductImagePicker] can call all three
  /// actions through one uniform "await, then use the returned path"
  /// pattern rather than special-casing removal.
  Future<String?> removeImage() async => null;
}
