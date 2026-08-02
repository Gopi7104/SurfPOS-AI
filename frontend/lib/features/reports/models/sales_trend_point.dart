/// One point on the Sales Chart's x-axis — [label] is already formatted
/// for the currently selected [ReportPeriod] (e.g. an hour for "Today", a
/// weekday for "7 Days", a month for "This Year"), so [ChartCard] never
/// needs to know which period produced it.
class SalesTrendPoint {
  const SalesTrendPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}
