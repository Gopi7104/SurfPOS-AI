/// One printed/shared receipt line — a snapshot of a [CartItemModel] at the
/// moment payment succeeded, not a live reference to the product (see
/// `CartItemModel`'s own header comment for why cart lines are snapshots).
class ReceiptLineItem {
  const ReceiptLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.productId,
    this.category,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  /// Carried through from `CartItemModel.product` so a completed sale can
  /// be attributed to a real product/category in Reports' sales ledger
  /// (see `SalesLedgerRepository`) — never displayed on the printed/shared
  /// receipt itself, which only ever showed [productName].
  final String? productId;
  final String? category;
}
