/// One "Business Insights" card's content — plain data; the widget layer
/// decides icon/tone per [kind] so this model stays Flutter-free like every
/// other model in this app.
enum InsightKind { growth, category, customer, inventory, lowStock }

class BusinessInsight {
  const BusinessInsight({required this.kind, required this.message});

  final InsightKind kind;
  final String message;
}
