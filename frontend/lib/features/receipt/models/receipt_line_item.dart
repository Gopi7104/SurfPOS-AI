/// One printed/shared receipt line — a snapshot of a [CartItemModel] at the
/// moment payment succeeded, not a live reference to the product (see
/// `CartItemModel`'s own header comment for why cart lines are snapshots).
class ReceiptLineItem {
  const ReceiptLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
}
