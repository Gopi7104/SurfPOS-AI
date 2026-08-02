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
    required this.customerId,
    required this.receiptNumber,
    required this.date,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.status,
  });

  /// Which customer this purchase belongs to — recorded by
  /// `CustomerRepository.recordPurchase` at the moment a sale completes
  /// (see `PaymentStatusPage`'s success hook); `getPurchaseHistory` filters
  /// the shared purchase store by this field.
  final String customerId;
  final String receiptNumber;
  final DateTime date;

  /// Product-name summary lines — this app has no persisted, structured
  /// order-line history, so a purchase is recorded as a flat list of names
  /// (the Receipt's line items at the moment of sale) rather than a richer
  /// line-item shape.
  final List<String> items;
  final double total;
  final String paymentMethod;
  final PurchaseStatus status;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'receiptNumber': receiptNumber,
        'date': date.millisecondsSinceEpoch,
        'items': items,
        'total': total,
        'paymentMethod': paymentMethod,
        'status': status.name,
      };

  factory CustomerPurchase.fromJson(Map<String, dynamic> json) {
    return CustomerPurchase(
      customerId: json['customerId'] as String,
      receiptNumber: json['receiptNumber'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      items: (json['items'] as List<dynamic>).cast<String>(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: PurchaseStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PurchaseStatus.completed,
      ),
    );
  }
}
