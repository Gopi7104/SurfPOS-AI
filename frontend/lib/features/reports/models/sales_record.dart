/// One product line within a [SalesRecord] — a snapshot of a
/// `ReceiptLineItem` at the moment payment succeeded, kept separately so
/// the sales ledger doesn't depend on the Receipt feature's model.
class SalesRecordItem {
  const SalesRecordItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.productId,
    this.category,
  });

  final String? productId;
  final String name;
  final String? category;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory SalesRecordItem.fromJson(Map<String, dynamic> json) {
    return SalesRecordItem(
      productId: json['productId'] as String?,
      name: json['name'] as String,
      category: json['category'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}

/// One completed sale — recorded once, at the moment a payment succeeds
/// (real Surfboard checkout or a Test Payment), by
/// `SalesLedgerRepository.recordSale`. This is the real, persisted
/// equivalent of `DemoSale`/`DemoBusinessSnapshot`: Dashboard and Reports
/// both derive every revenue/order/product/category figure from this
/// ledger once at least one real sale exists, falling back to demo data
/// only until then (see `SalesLedgerSnapshot`).
class SalesRecord {
  const SalesRecord({
    required this.id,
    required this.receiptNumber,
    required this.occurredAt,
    required this.total,
    required this.paymentMethod,
    required this.items,
    this.customerId,
    this.customerName,
  });

  final String id;
  final String receiptNumber;
  final DateTime occurredAt;
  final double total;
  final String paymentMethod;
  final List<SalesRecordItem> items;
  final String? customerId;
  final String? customerName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'occurredAt': occurredAt.millisecondsSinceEpoch,
        'total': total,
        'paymentMethod': paymentMethod,
        'items': items.map((item) => item.toJson()).toList(),
        'customerId': customerId,
        'customerName': customerName,
      };

  factory SalesRecord.fromJson(Map<String, dynamic> json) {
    return SalesRecord(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(json['occurredAt'] as int),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => SalesRecordItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
    );
  }
}
