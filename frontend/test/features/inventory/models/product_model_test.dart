import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/models/product_model.dart';
import 'package:surfpos_ai/features/inventory/models/product_status.dart';

Map<String, dynamic> _json({
  double? sellingPrice = 19.99,
  int? stockQuantity = 10,
  int? reorderLevel = 5,
  String? status = 'ACTIVE',
}) {
  return {
    'id': 'prod-1',
    'merchantId': 'm-1',
    'name': 'Wax',
    'sku': 'WAX-01',
    'unit': 'pcs',
    'sellingPrice': sellingPrice,
    'costPrice': 9.99,
    'taxRate': 25,
    'discountPercentage': 10,
    'reorderLevel': reorderLevel,
    'stockQuantity': stockQuantity,
    'status': status,
    'isActive': true,
    'createdAt': 1000,
    'updatedAt': 2000,
  };
}

void main() {
  group('ProductModel.fromJson', () {
    test('maps the backend field names to the friendly UI-facing ones', () {
      final product = ProductModel.fromJson(_json());

      expect(product.price, 19.99, reason: 'sellingPrice -> price');
      expect(product.taxPercentage, 25, reason: 'taxRate -> taxPercentage');
      expect(product.lowStockThreshold, 5,
          reason: 'reorderLevel -> lowStockThreshold');
      expect(product.status, ProductStatus.active);
      expect(product.createdAt, DateTime.fromMillisecondsSinceEpoch(1000));
      expect(product.updatedAt, DateTime.fromMillisecondsSinceEpoch(2000));
    });

    test('defaults to INACTIVE/active mapping correctly for both wire values',
        () {
      expect(ProductModel.fromJson(_json(status: 'INACTIVE')).status,
          ProductStatus.inactive);
      expect(ProductModel.fromJson(_json(status: null)).status,
          ProductStatus.active);
    });
  });

  group('stock derived getters', () {
    test('isOutOfStock is true only when stockQuantity is 0', () {
      expect(
          ProductModel.fromJson(_json(stockQuantity: 0)).isOutOfStock, isTrue);
      expect(
          ProductModel.fromJson(_json(stockQuantity: 1)).isOutOfStock, isFalse);
    });

    test('isLowStock is true only when in-stock and at/below the threshold',
        () {
      expect(
          ProductModel.fromJson(_json(stockQuantity: 5, reorderLevel: 5))
              .isLowStock,
          isTrue);
      expect(
          ProductModel.fromJson(_json(stockQuantity: 6, reorderLevel: 5))
              .isLowStock,
          isFalse);
      expect(
          ProductModel.fromJson(_json(stockQuantity: 0, reorderLevel: 5))
              .isLowStock,
          isFalse,
          reason: 'out of stock is a distinct state from low stock');
      expect(
          ProductModel.fromJson(_json(stockQuantity: 2, reorderLevel: null))
              .isLowStock,
          isFalse,
          reason: 'no threshold set means low-stock is never signaled');
    });
  });
}
