import '../models/product_draft.dart';
import '../models/product_model.dart';

/// Builds a [ProductDraft] carrying exactly [product]'s current catalog
/// field values, unchanged — used wherever a UI action needs to resubmit a
/// product through [InventoryFormController.updateProduct] without editing
/// any catalog field itself (e.g. Quick Restock, Adjust Stock: only the
/// `stockDelta` param actually changes anything, `updateProduct`'s own
/// `PATCH` becomes a no-op). Plain field mapping, no business logic.
ProductDraft draftFromProduct(ProductModel product) {
  return ProductDraft(
    name: product.name,
    description: product.description,
    sku: product.sku,
    barcode: product.barcode,
    category: product.category,
    unit: product.unit,
    price: product.price,
    costPrice: product.costPrice,
    taxPercentage: product.taxPercentage,
    discountPercentage: product.discountPercentage,
    lowStockThreshold: product.lowStockThreshold,
    imageUrl: product.imageUrl,
    imagePath: product.imagePath,
    status: product.status,
  );
}
