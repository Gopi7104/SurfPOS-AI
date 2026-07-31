import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_query.dart';
import 'package:surfpos_ai/features/inventory/models/product_draft.dart';
import 'package:surfpos_ai/features/inventory/models/product_model.dart';
import 'package:surfpos_ai/features/inventory/models/product_status.dart';
import 'package:surfpos_ai/features/inventory/repositories/inventory_repository.dart';

/// Configurable [InventoryRepository] test double — mirrors
/// `fake_dashboard_repository.dart`'s shape: every method defaults to a
/// no-op/empty behavior, overridable per test via the constructor, never
/// touching the real network.
class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository({
    Future<InventoryPage> Function(InventoryQuery query,
            {String? cursor, int limit})?
        listProducts,
    Future<ProductModel> Function(String productId)? getProduct,
    Future<ProductModel> Function(ProductDraft draft,
            {int? initialStock, String? storeId})?
        createProduct,
    Future<ProductModel> Function(String productId, ProductDraft draft)?
        updateProduct,
    Future<void> Function(String productId)? deleteProduct,
    Future<void> Function(String productId,
            {required String storeId, required int quantityDelta})?
        adjustStock,
    Future<List<String>> Function()? listCategories,
    Future<String?> Function()? pickImageFromGallery,
    Future<String?> Function()? captureImageFromCamera,
  })  : _pickImageFromGallery = pickImageFromGallery ?? (() async => null),
        _captureImageFromCamera = captureImageFromCamera ?? (() async => null),
        _listProducts = listProducts ??
            ((query, {cursor, limit = 20}) async =>
                const InventoryPage(items: [], nextCursor: null)),
        _getProduct = getProduct,
        _createProduct = createProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct ?? ((productId) async {}),
        _adjustStock = adjustStock ??
            ((productId, {required storeId, required quantityDelta}) async {}),
        _listCategories = listCategories ?? (() async => const []);

  final Future<InventoryPage> Function(InventoryQuery query,
      {String? cursor, int limit}) _listProducts;
  final Future<ProductModel> Function(String productId)? _getProduct;
  final Future<ProductModel> Function(ProductDraft draft,
      {int? initialStock, String? storeId})? _createProduct;
  final Future<ProductModel> Function(String productId, ProductDraft draft)?
      _updateProduct;
  final Future<void> Function(String productId) _deleteProduct;
  final Future<void> Function(String productId,
      {required String storeId, required int quantityDelta}) _adjustStock;
  final Future<List<String>> Function() _listCategories;
  final Future<String?> Function() _pickImageFromGallery;
  final Future<String?> Function() _captureImageFromCamera;

  @override
  Future<InventoryPage> listProducts(InventoryQuery query,
          {String? cursor, int limit = 20}) =>
      _listProducts(query, cursor: cursor, limit: limit);

  @override
  Future<ProductModel> getProduct(String productId) {
    final getProduct = _getProduct;
    if (getProduct == null) throw UnimplementedError();
    return getProduct(productId);
  }

  @override
  Future<ProductModel> createProduct(ProductDraft draft,
      {int? initialStock, String? storeId}) {
    final createProduct = _createProduct;
    if (createProduct == null) throw UnimplementedError();
    return createProduct(draft, initialStock: initialStock, storeId: storeId);
  }

  @override
  Future<ProductModel> updateProduct(String productId, ProductDraft draft) {
    final updateProduct = _updateProduct;
    if (updateProduct == null) throw UnimplementedError();
    return updateProduct(productId, draft);
  }

  @override
  Future<void> deleteProduct(String productId) => _deleteProduct(productId);

  @override
  Future<void> adjustStock(String productId,
          {required String storeId, required int quantityDelta}) =>
      _adjustStock(productId, storeId: storeId, quantityDelta: quantityDelta);

  @override
  Future<List<String>> listCategories() => _listCategories();

  @override
  Future<String?> pickImageFromGallery() => _pickImageFromGallery();

  @override
  Future<String?> captureImageFromCamera() => _captureImageFromCamera();
}

ProductModel testProduct({
  String id = 'prod-1',
  String name = 'Blue Wave Surf Wax',
  String sku = 'WAX-01',
  String? category = 'Wax',
  double price = 19.99,
  double costPrice = 9.99,
  int stockQuantity = 25,
  int? lowStockThreshold = 5,
  ProductStatus status = ProductStatus.active,
  String? imagePath,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductModel(
    id: id,
    merchantId: 'm-1',
    name: name,
    sku: sku,
    category: category,
    unit: 'pcs',
    imagePath: imagePath,
    price: price,
    costPrice: costPrice,
    taxPercentage: 0,
    discountPercentage: 0,
    lowStockThreshold: lowStockThreshold,
    stockQuantity: stockQuantity,
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
