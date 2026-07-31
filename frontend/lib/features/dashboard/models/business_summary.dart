/// Today's business KPIs. Always zero for now — Billing/Inventory aren't
/// implemented yet (Phase 1, see docs/22_DEVELOPMENT_ROADMAP.md), so there is
/// no real data source to read this from. Replace with a real repository
/// call once Billing exists; the Dashboard UI already renders whatever
/// values land here, so no UI change will be needed at that point.
class BusinessSummary {
  const BusinessSummary({
    this.todaySales = 0,
    this.todayOrders = 0,
    this.todayCustomers = 0,
    this.productsCount = 0,
  });

  final num todaySales;
  final int todayOrders;
  final int todayCustomers;
  final int productsCount;
}
