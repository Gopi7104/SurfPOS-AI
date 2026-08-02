import 'dart:math';

import '../../reports/models/recent_transaction.dart';
import '../models/demo_business_snapshot.dart';
import '../models/demo_customer.dart';
import '../models/demo_product.dart';
import '../models/demo_receipt.dart';
import '../models/demo_sale.dart';

/// Generates a realistic-looking [DemoBusinessSnapshot] entirely in memory
/// — 50 products across 10 categories, 200 customers, 300 sales, and 100
/// receipts. This is a **presentation-only** fixture for the redesigned
/// Dashboard: nothing here is ever written to `InventoryRepository`,
/// `CustomerRepository`, or any other real repository/backend — see
/// `DemoDataController`'s header comment for how it's stored (a separate,
/// local-only blob) and never mixed into a merchant's real catalog/customer
/// list/sales history.
class DemoDataGenerator {
  const DemoDataGenerator();

  static const _categoryProducts = <String, List<String>>{
    'Surf Wax': [
      'Tropical Surf Wax',
      'Cold Water Surf Wax',
      'Basecoat Surf Wax',
      'Coconut Surf Wax',
      'Citrus Surf Wax',
    ],
    'Wetsuits': [
      '3/2mm Fullsuit',
      '4/3mm Fullsuit',
      'Springsuit Short Arm',
      "Women's Fullsuit 3/2mm",
      'Kids Wetsuit 2mm',
    ],
    'Boardshorts': [
      'Classic Boardshorts',
      'Stretch Boardshorts',
      'Print Boardshorts',
      'Volley Shorts',
      'Hybrid Walkshorts',
    ],
    'Rash Guards': [
      'Long Sleeve Rash Guard',
      'Short Sleeve Rash Guard',
      'UV Protection Rashie',
      "Women's Rash Guard",
      'Kids Rash Guard',
    ],
    'Fins': [
      'Thruster Fin Set',
      'Quad Fin Set',
      'Single Fin',
      'Twin Fin Set',
      'Performance Fin Set',
    ],
    'Leashes': [
      '6ft Comp Leash',
      '7ft Leash',
      '8ft Leash',
      'Kneeboard Leash',
      'Coiled Leash',
    ],
    'Sunglasses': [
      'Polarized Sunglasses',
      'Floating Sunglasses',
      'Sport Sunglasses',
      'Classic Sunglasses',
      'Mirrored Sunglasses',
    ],
    'Sunscreen': [
      'SPF50 Sunscreen',
      'Zinc Sunscreen Stick',
      'Reef Safe Sunscreen',
      'SPF30 Sunscreen Spray',
      'Tinted Zinc Sunscreen',
    ],
    'Accessories': [
      'Wax Comb',
      'Board Bag',
      'Roof Rack Pads',
      'Traction Pad',
      'Fin Key',
    ],
    'Apparel': [
      'Surf Hoodie',
      'Graphic Tee',
      'Snapback Cap',
      'Boardshort Belt',
      'Surf Poncho',
    ],
  };

  static const _firstNames = [
    'Olivia',
    'Liam',
    'Emma',
    'Noah',
    'Ava',
    'Elijah',
    'Sophia',
    'Lucas',
    'Isabella',
    'Mason',
    'Mia',
    'Ethan',
    'Amelia',
    'James',
    'Harper',
    'Logan',
    'Evelyn',
    'Aiden',
    'Abigail',
    'Jack',
    'Emily',
    'Owen',
    'Charlotte',
    'Wyatt',
    'Ella',
    'Leo',
    'Grace',
    'Gabriel',
    'Chloe',
    'Julian',
  ];

  static const _lastNames = [
    'Andersson',
    'Berg',
    'Carlsson',
    'Dahl',
    'Eriksson',
    'Forsberg',
    'Gustafsson',
    'Holm',
    'Isaksson',
    'Johansson',
    'Karlsson',
    'Lindqvist',
    'Nilsson',
    'Olsson',
    'Pettersson',
    'Svensson',
    'Wallin',
    'Åberg',
    'Bergström',
    'Lindgren',
  ];

  static const _paymentMethods = ['Cash', 'Card', 'Mobile Payment', 'Test'];
  static const _paymentWeights = [0.35, 0.45, 0.15, 0.05];

  static const _statuses = [
    TransactionStatus.successful,
    TransactionStatus.cancelled,
    TransactionStatus.failed,
  ];
  static const _statusWeights = [0.92, 0.05, 0.03];

  DemoBusinessSnapshot generate({
    String? merchantName,
    String? storeName,
  }) {
    final random = Random();
    final now = DateTime.now();
    final categories = _categoryProducts.keys.toList();

    final products = _generateProducts(random, categories);
    final customers = _generateCustomers(random);

    final unitsSold = <String, int>{};
    final customerSpend = <String, double>{};
    final customerOrders = <String, int>{};

    final sales = _generateSales(
      random: random,
      now: now,
      products: products,
      customers: customers,
      onUnitSold: (productId) =>
          unitsSold[productId] = (unitsSold[productId] ?? 0) + 1,
      onCustomerPurchase: (customerId, amount) {
        customerSpend[customerId] = (customerSpend[customerId] ?? 0) + amount;
        customerOrders[customerId] = (customerOrders[customerId] ?? 0) + 1;
      },
    );

    final finalProducts = [
      for (final product in products)
        DemoProduct(
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price,
          costPrice: product.costPrice,
          stockQuantity: product.stockQuantity,
          lowStockThreshold: product.lowStockThreshold,
          unitsSold: unitsSold[product.id] ?? 0,
          colorSeed: product.colorSeed,
        ),
    ];

    final finalCustomers = [
      for (final customer in customers)
        DemoCustomer(
          id: customer.id,
          name: customer.name,
          totalSpend: customerSpend[customer.id] ?? 0,
          totalOrders: customerOrders[customer.id] ?? 0,
        ),
    ];

    final receipts = _generateReceipts(random, sales);

    return DemoBusinessSnapshot(
      merchantName:
          merchantName?.isNotEmpty == true ? merchantName! : 'Surf Shack Co.',
      storeName:
          storeName?.isNotEmpty == true ? storeName! : 'Main Street Store',
      generatedAt: now,
      categories: categories,
      products: finalProducts,
      customers: finalCustomers,
      sales: sales,
      receipts: receipts,
    );
  }

  List<_ProductSeed> _generateProducts(Random random, List<String> categories) {
    final products = <_ProductSeed>[];
    var index = 0;
    for (final category in categories) {
      for (final name in _categoryProducts[category]!) {
        final price = (8 + random.nextInt(85)) + 0.99;
        final costPrice = price * (0.4 + random.nextDouble() * 0.2);
        products.add(_ProductSeed(
          id: 'demo-product-${index + 1}',
          name: name,
          category: category,
          price: double.parse(price.toStringAsFixed(2)),
          costPrice: double.parse(costPrice.toStringAsFixed(2)),
          stockQuantity: random.nextInt(120),
          lowStockThreshold: 10,
          colorSeed: index,
        ));
        index++;
      }
    }
    return products;
  }

  List<_CustomerSeed> _generateCustomers(Random random) {
    return List.generate(200, (i) {
      final first = _firstNames[random.nextInt(_firstNames.length)];
      final last = _lastNames[random.nextInt(_lastNames.length)];
      return _CustomerSeed(id: 'demo-customer-${i + 1}', name: '$first $last');
    });
  }

  List<DemoSale> _generateSales({
    required Random random,
    required DateTime now,
    required List<_ProductSeed> products,
    required List<_CustomerSeed> customers,
    required void Function(String productId) onUnitSold,
    required void Function(String customerId, double amount) onCustomerPurchase,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final sales = <DemoSale>[];

    for (var i = 0; i < 300; i++) {
      // Skews toward more recent days (squaring a 0..1 value biases small
      // offsets) — a real shop sells more consistently near "today" than
      // 45 days ago. Sale 0 is forced to day-offset 0 so `latestSaleDay`
      // always resolves to "today" regardless of how the random draws land.
      final dayOffset =
          i == 0 ? 0 : (pow(random.nextDouble(), 1.6) * 45).floor();
      final hour = 8 + random.nextInt(13); // 8am – 9pm
      final minute = random.nextInt(60);
      final time = today
          .subtract(Duration(days: dayOffset))
          .add(Duration(hours: hour, minutes: minute));

      final product = products[random.nextInt(products.length)];
      final hasCustomer = random.nextDouble() < 0.7;
      final customer =
          hasCustomer ? customers[random.nextInt(customers.length)] : null;
      final status = _weightedPick(random, _statuses, _statusWeights);
      final paymentMethod =
          _weightedPick(random, _paymentMethods, _paymentWeights);

      final sale = DemoSale(
        id: 'demo-sale-${i + 1}',
        receiptNumber: 'RCPT-${(i + 1).toString().padLeft(5, '0')}',
        time: time,
        amount: product.price,
        costAmount: product.costPrice,
        paymentMethod: paymentMethod,
        productId: product.id,
        productName: product.name,
        customerName: customer?.name,
        status: status,
      );
      sales.add(sale);

      if (status != TransactionStatus.failed) {
        onUnitSold(product.id);
        if (customer != null) onCustomerPurchase(customer.id, product.price);
      }
    }

    return sales;
  }

  List<DemoReceipt> _generateReceipts(Random random, List<DemoSale> sales) {
    final shuffled = [...sales]..shuffle(random);
    return shuffled
        .take(100)
        .map((sale) => DemoReceipt(
              receiptNumber: sale.receiptNumber,
              saleId: sale.id,
              amount: sale.amount,
              time: sale.time,
            ))
        .toList();
  }

  T _weightedPick<T>(Random random, List<T> values, List<double> weights) {
    final roll = random.nextDouble();
    var cumulative = 0.0;
    for (var i = 0; i < values.length; i++) {
      cumulative += weights[i];
      if (roll <= cumulative) return values[i];
    }
    return values.last;
  }
}

class _ProductSeed {
  const _ProductSeed({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.colorSeed,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double costPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final int colorSeed;
}

class _CustomerSeed {
  const _CustomerSeed({required this.id, required this.name});

  final String id;
  final String name;
}
