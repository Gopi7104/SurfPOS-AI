/// One slice of the Category Breakdown pie chart.
class CategoryBreakdownSlice {
  const CategoryBreakdownSlice({
    required this.category,
    required this.revenue,
    required this.percentage,
  });

  final String category;
  final double revenue;

  /// `0.0`–`100.0`, of total revenue across every slice.
  final double percentage;
}
