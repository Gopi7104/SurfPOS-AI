/// One slice of Reports' Revenue Breakdown chart — Reports' own copy of
/// the same {method, amount, percentage} shape `demo_data`'s
/// `PaymentBreakdownSlice` uses for Dashboard, kept separate so Reports
/// never depends on the Demo Data feature's models (see
/// `docs/07_CODING_RULES.md` § layering).
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
