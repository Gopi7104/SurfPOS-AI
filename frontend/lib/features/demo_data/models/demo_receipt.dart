/// One fake issued receipt — a subset of [DemoSale]s that "printed a
/// receipt" (not every walk-in sale does, realistically). Presentation-only.
class DemoReceipt {
  const DemoReceipt({
    required this.receiptNumber,
    required this.saleId,
    required this.amount,
    required this.time,
  });

  final String receiptNumber;
  final String saleId;
  final double amount;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'receiptNumber': receiptNumber,
        'saleId': saleId,
        'amount': amount,
        'time': time.millisecondsSinceEpoch,
      };

  factory DemoReceipt.fromJson(Map<String, dynamic> json) => DemoReceipt(
        receiptNumber: json['receiptNumber'] as String,
        saleId: json['saleId'] as String,
        amount: (json['amount'] as num).toDouble(),
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      );
}
