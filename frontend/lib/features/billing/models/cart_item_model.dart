import '../../inventory/models/product_model.dart';

/// One line in the cart — a [product] snapshot (captured at add-time, so a
/// later Inventory price/tax edit never silently changes an in-progress
/// sale) plus the [quantity] the cashier has selected. Per-line tax and
/// discount are derived from the product's own `taxPercentage`/
/// `discountPercentage` (already configured in Inventory) — Billing never
/// invents its own tax/discount rates (see
/// docs/22_DEVELOPMENT_ROADMAP.md, Phase 3: "Taxes configuration" is
/// explicitly out of scope for this phase).
class CartItemModel {
  const CartItemModel({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  double get unitPrice => product.price;

  /// Pre-tax, pre-discount line value.
  double get lineSubtotal => unitPrice * quantity;

  double get lineDiscount => lineSubtotal * (product.discountPercentage / 100);

  double get lineTax =>
      (lineSubtotal - lineDiscount) * (product.taxPercentage / 100);

  double get lineTotal => lineSubtotal - lineDiscount + lineTax;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(product: product, quantity: quantity ?? this.quantity);
  }
}
