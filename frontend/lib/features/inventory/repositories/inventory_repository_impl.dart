import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/inventory_page.dart';
import '../models/inventory_query.dart';
import '../models/product_draft.dart';
import '../models/product_image_exception.dart';
import '../models/product_model.dart';
import 'inventory_repository.dart';
import 'product_image_local_storage.dart';

const _categoriesSampleLimit = 100;

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    required ApiClient apiClient,
    required ProductImageLocalStorage imageLocalStorage,
    ImagePicker? imagePicker,
  })  : _apiClient = apiClient,
        _imageLocalStorage = imageLocalStorage,
        _imagePicker = imagePicker ?? ImagePicker();

  final ApiClient _apiClient;
  final ProductImageLocalStorage _imageLocalStorage;
  final ImagePicker _imagePicker;

  @override
  Future<InventoryPage> listProducts(InventoryQuery query,
      {String? cursor, int limit = 20}) async {
    final data = await _apiClient.get(
      '/inventory/products',
      requiresAuth: true,
      queryParameters: query.toQueryParameters(limit: limit, cursor: cursor),
    );
    final page = InventoryPage.fromJson(data);

    final imagePaths = await _imageLocalStorage
        .getMany(page.items.map((product) => product.id));
    if (imagePaths.isEmpty) return page;
    return InventoryPage(
      items: [
        for (final product in page.items)
          product.copyWith(imagePath: imagePaths[product.id]),
      ],
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<ProductModel> getProduct(String productId) async {
    final data = await _apiClient.get('/inventory/products/$productId',
        requiresAuth: true);
    final imagePath = await _imageLocalStorage.get(productId);
    return ProductModel.fromJson(data['product'] as Map<String, dynamic>,
        imagePath: imagePath);
  }

  @override
  Future<ProductModel> createProduct(ProductDraft draft,
      {int? initialStock, String? storeId}) async {
    final data = await _apiClient.post(
      '/inventory/products',
      body: draft.toJson(),
      requiresAuth: true,
    );
    var product =
        ProductModel.fromJson(data['product'] as Map<String, dynamic>);

    if (draft.imagePath != null) {
      await _imageLocalStorage.set(product.id, draft.imagePath);
      product = product.copyWith(imagePath: draft.imagePath);
    }

    // Setting an opening stock count is a second call (adjustStock requires an explicit
    // storeId — the backend never guesses which store a stock *write* applies to, unlike
    // reads, which fall back to the merchant's primary store). storeId is resolved by the
    // caller (InventoryFormController, from the already-loaded Dashboard store profile) —
    // the repository has no Riverpod `ref` to resolve it itself. Silently skipped (product
    // creation still succeeds) if the merchant has no store yet.
    if (initialStock != null && initialStock > 0 && storeId != null) {
      await adjustStock(product.id,
          storeId: storeId, quantityDelta: initialStock);
      product = await getProduct(product.id);
    }
    return product;
  }

  @override
  Future<ProductModel> updateProduct(
      String productId, ProductDraft draft) async {
    final data = await _apiClient.patch(
      '/inventory/products/$productId',
      body: draft.toJson(),
      requiresAuth: true,
    );
    await _imageLocalStorage.set(productId, draft.imagePath);
    return ProductModel.fromJson(data['product'] as Map<String, dynamic>,
        imagePath: draft.imagePath);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _apiClient.delete('/inventory/products/$productId',
        requiresAuth: true);
    await _imageLocalStorage.remove(productId);
  }

  @override
  Future<void> adjustStock(String productId,
      {required String storeId, required int quantityDelta}) async {
    await _apiClient.patch(
      '/inventory/products/$productId/stock',
      body: {'storeId': storeId, 'quantityDelta': quantityDelta},
      requiresAuth: true,
    );
  }

  @override
  Future<List<String>> listCategories() async {
    final page = await listProducts(const InventoryQuery(),
        limit: _categoriesSampleLimit);
    final categories = page.items
        .map((product) => product.category)
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  @override
  Future<String?> pickImageFromGallery() => _pickImage(ImageSource.gallery);

  @override
  Future<String?> captureImageFromCamera() => _pickImage(ImageSource.camera);

  Future<String?> _pickImage(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(source: source);
    } on PlatformException catch (error) {
      throw ProductImageException(_messageForPlatformException(error, source));
    } catch (error) {
      throw const ProductImageException(
          'Could not open the camera or gallery. Please try again.');
    }

    if (picked == null) return null; // user cancelled — not an error

    final file = File(picked.path);
    if (!await file.exists()) {
      throw const ProductImageException(
          'The selected image could not be found.');
    }
    return picked.path;
  }

  String _messageForPlatformException(
      PlatformException error, ImageSource source) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      final feature = source == ImageSource.camera ? 'Camera' : 'Photo library';
      return '$feature access is denied. Enable it in your device Settings to continue.';
    }
    if (source == ImageSource.camera) {
      return 'The camera is unavailable on this device.';
    }
    return error.message ?? 'Could not select an image. Please try again.';
  }
}
