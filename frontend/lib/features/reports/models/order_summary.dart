/// Orders section KPIs — Today's Orders/Completed/Cancelled/Average Order
/// Value. See [SalesSummary]'s header comment for why these start at zero.
class OrderSummary {
  const OrderSummary({
    required this.todayOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
  });

  final int todayOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;

  factory OrderSummary.empty() => const OrderSummary(
        todayOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        averageOrderValue: 0,
      );
}
