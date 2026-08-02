/// One row in a customer's Purchase History.
enum PurchaseStatus {
  completed,
  cancelled,
  refunded;

  String get label => switch (this) {
        PurchaseStatus.completed => 'Completed',
        PurchaseStatus.cancelled => 'Cancelled',
        PurchaseStatus.refunded => 'Refunded',
      };
}

class CustomerPurchase {
  const CustomerPurchase({
    required this.receiptNumber,
    required this.date,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.status,
  });

  final String receiptNumber;
  final DateTime date;

  /// Product-name summary lines — this app has no persisted, structured
  /// order-line history yet (see [CustomerRepositoryImpl]'s header
  /// comment), so a purchase is recorded as a flat list of names rather
  /// than a richer line-item shape once a real source exists.
  final List<String> items;
  final double total;
  final String paymentMethod;
  final PurchaseStatus status;
}
