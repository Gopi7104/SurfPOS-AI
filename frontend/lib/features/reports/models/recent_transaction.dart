/// One row in the Recent Transactions section (latest 20).
enum TransactionStatus {
  successful,
  failed,
  cancelled;

  String get label => switch (this) {
        TransactionStatus.successful => 'Successful',
        TransactionStatus.failed => 'Failed',
        TransactionStatus.cancelled => 'Cancelled',
      };
}

class RecentTransaction {
  const RecentTransaction({
    required this.receiptNumber,
    this.customerName,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.time,
  });

  final String receiptNumber;

  /// `null` renders as "Walk-in" — Checkout doesn't collect a customer name
  /// today (see `PaymentSummaryDialog`), so this is never populated yet.
  final String? customerName;
  final double amount;
  final TransactionStatus status;
  final String paymentMethod;
  final DateTime time;
}
