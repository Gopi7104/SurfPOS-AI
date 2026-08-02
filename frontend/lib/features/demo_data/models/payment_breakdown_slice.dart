/// One slice of the Payment Breakdown donut chart — Cash/Card/Mobile
/// Payment/Test, by revenue share.
class PaymentBreakdownSlice {
  const PaymentBreakdownSlice({
    required this.method,
    required this.amount,
    required this.percentage,
  });

  final String method;
  final double amount;

  /// `0.0`–`100.0`, of total revenue across every slice.
  final double percentage;
}
