/// One fake customer in a generated demo catalog — presentation-only,
/// never written to the real `CustomerRepository`/local storage.
class DemoCustomer {
  const DemoCustomer({
    required this.id,
    required this.name,
    required this.totalSpend,
    required this.totalOrders,
  });

  final String id;
  final String name;
  final double totalSpend;
  final int totalOrders;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalSpend': totalSpend,
        'totalOrders': totalOrders,
      };

  factory DemoCustomer.fromJson(Map<String, dynamic> json) => DemoCustomer(
        id: json['id'] as String,
        name: json['name'] as String,
        totalSpend: (json['totalSpend'] as num).toDouble(),
        totalOrders: json['totalOrders'] as int,
      );
}
