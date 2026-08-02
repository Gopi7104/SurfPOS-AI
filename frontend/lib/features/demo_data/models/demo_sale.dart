import '../../reports/models/recent_transaction.dart' show TransactionStatus;

/// One fake completed sale — presentation-only. Reuses Reports'
/// [TransactionStatus] (a generic, feature-agnostic enum) rather than
/// declaring a duplicate; never touches any Reports code or data.
class DemoSale {
  const DemoSale({
    required this.id,
    required this.receiptNumber,
    required this.time,
    required this.amount,
    required this.costAmount,
    required this.paymentMethod,
    required this.productId,
    required this.productName,
    this.customerName,
    required this.status,
  });

  final String id;
  final String receiptNumber;
  final DateTime time;
  final double amount;
  final double costAmount;

  /// One of "Cash", "Card", "Mobile Payment", "Test" — see
  /// `DemoDataGenerator`'s payment-method weighting.
  final String paymentMethod;
  final String productId;
  final String productName;

  /// `null` renders as "Walk-in" — mirrors real Checkout, which doesn't
  /// collect a customer name either.
  final String? customerName;
  final TransactionStatus status;

  double get profit => amount - costAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'time': time.millisecondsSinceEpoch,
        'amount': amount,
        'costAmount': costAmount,
        'paymentMethod': paymentMethod,
        'productId': productId,
        'productName': productName,
        'customerName': customerName,
        'status': status.name,
      };

  factory DemoSale.fromJson(Map<String, dynamic> json) => DemoSale(
        id: json['id'] as String,
        receiptNumber: json['receiptNumber'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        amount: (json['amount'] as num).toDouble(),
        costAmount: (json['costAmount'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        customerName: json['customerName'] as String?,
        status: TransactionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TransactionStatus.successful,
        ),
      );
}
