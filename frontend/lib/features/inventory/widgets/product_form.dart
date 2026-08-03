import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';
import '../models/product_draft.dart';
import '../models/product_lookup_result.dart';
import '../models/product_model.dart';
import '../models/product_status.dart';
import 'product_image_picker.dart';

/// [ProductForm]'s validated output — the catalog fields as a [ProductDraft]
/// plus the raw stock quantity entered, kept separate since stock isn't a
/// catalog field the backend accepts on create/update (see
/// `InventoryRepository.createProduct`'s `initialStock`/`adjustStock`).
class ProductFormResult {
  const ProductFormResult({required this.draft, required this.stockQuantity});

  final ProductDraft draft;
  final int stockQuantity;
}

/// Shared Add/Edit Product form body — same conventions as
/// `BusinessStepScreen`: self-contained controllers, feedback-only
/// validation, reports a validated result via [onSubmit]. [initial] pre-
/// fills every field for Edit; omitted (null) for Add.
class ProductForm extends StatefulWidget {
  const ProductForm({
    required this.uid,
    this.initial,
    this.prefill,
    required this.onSubmit,
    this.isSubmitting = false,
    this.errorMessage,
    this.submitLabel = 'Save',
    super.key,
  });

  /// Threaded down to [ProductImagePicker], which resolves the same
  /// `inventoryFormControllerProvider(uid)` this form submits through.
  final String uid;
  final ProductModel? initial;

  /// A barcode scan's resolved product info — only consulted when
  /// [initial] is null (Add mode; Edit always shows the real saved
  /// product). Name/Category/Barcode/Image prefill their matching field
  /// directly; Brand/Weight/Ingredients/Nutrition/Packaging/Country (no
  /// dedicated catalog field exists for these) are folded into Description
  /// as editable text. Price/Cost/Tax/Stock/SKU/Low Stock Threshold are
  /// never touched — those are always store-specific and merchant-entered.
  final ProductLookupResult? prefill;
  final ValueChanged<ProductFormResult> onSubmit;
  final bool isSubmitting;
  final String? errorMessage;
  final String submitLabel;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late final _nameController = TextEditingController(
      text: widget.initial?.name ?? widget.prefill?.name ?? '');
  late final _descriptionController = TextEditingController(
      text: widget.initial?.description ??
          _composeEnrichedDescription(widget.prefill) ??
          '');
  late final _skuController =
      TextEditingController(text: widget.initial?.sku ?? _generateSku());
  late final _barcodeController = TextEditingController(
      text: widget.initial?.barcode ?? widget.prefill?.barcode ?? '');
  late final _categoryController = TextEditingController(
      text: widget.initial?.category ?? widget.prefill?.category ?? '');
  late final _unitController =
      TextEditingController(text: widget.initial?.unit ?? 'pcs');
  late final _priceController = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.price.toString());
  late final _costPriceController = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.costPrice.toString());
  late final _taxController = TextEditingController(
    text:
        widget.initial == null ? '0' : widget.initial!.taxPercentage.toString(),
  );
  late final _discountController = TextEditingController(
    text: widget.initial == null
        ? '0'
        : widget.initial!.discountPercentage.toString(),
  );
  late final _stockController = TextEditingController(
    text:
        widget.initial == null ? '0' : widget.initial!.stockQuantity.toString(),
  );
  late final _lowStockController = TextEditingController(
    text: widget.initial?.lowStockThreshold?.toString() ?? '',
  );
  late String? _imagePath = widget.initial?.imagePath;
  late String? _imageUrl = widget.initial?.imageUrl ?? widget.prefill?.imageUrl;

  String? _nameError;
  String? _skuError;
  String? _unitError;
  String? _priceError;
  String? _costPriceError;
  String? _stockError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  /// An effectively-unique SKU for a brand-new product (Add mode only —
  /// Edit/Duplicate always pass [ProductForm.initial], so its real saved
  /// SKU wins via the `??` above) — millisecond timestamp + a short random
  /// suffix, so the merchant never has to type one, and two products added
  /// back-to-back still can't collide. The backend remains the source of
  /// truth for uniqueness (`InventoryService.assertSkuAvailable`); this
  /// only saves manual entry, it doesn't replace that check.
  static String _generateSku() {
    final millis =
        DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final suffix = Random()
        .nextInt(0xFFFF)
        .toRadixString(36)
        .padLeft(3, '0')
        .toUpperCase();
    return 'SKU-$millis-$suffix';
  }

  double? _parseNonNegative(String text) {
    final value = double.tryParse(text.trim());
    if (value == null || value < 0) return null;
    return value;
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final unit = _unitController.text.trim();
    final price = _parseNonNegative(_priceController.text);
    final costPrice = _parseNonNegative(_costPriceController.text);
    final stock = int.tryParse(_stockController.text.trim());

    setState(() {
      _nameError = name.length < 2 ? 'Enter at least 2 characters' : null;
      _skuError = sku.isEmpty ? 'SKU is required' : null;
      _unitError = unit.isEmpty ? 'Unit is required' : null;
      _priceError = price == null ? 'Enter a valid price' : null;
      _costPriceError = costPrice == null ? 'Enter a valid cost price' : null;
      _stockError =
          (stock == null || stock < 0) ? 'Enter a valid stock quantity' : null;
    });

    if ([
      _nameError,
      _skuError,
      _unitError,
      _priceError,
      _costPriceError,
      _stockError
    ].any((error) => error != null)) {
      return;
    }

    final tax = _parseNonNegative(_taxController.text) ?? 0;
    final discount = _parseNonNegative(_discountController.text) ?? 0;
    final lowStockText = _lowStockController.text.trim();
    final lowStockThreshold =
        lowStockText.isEmpty ? null : int.tryParse(lowStockText);

    widget.onSubmit(
      ProductFormResult(
        draft: ProductDraft(
          name: name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          sku: sku,
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          unit: unit,
          price: price!,
          costPrice: costPrice!,
          taxPercentage: tax,
          discountPercentage: discount,
          lowStockThreshold: lowStockThreshold,
          imageUrl: _imageUrl,
          imagePath: _imagePath,
          status: widget.initial?.status ?? ProductStatus.active,
        ),
        stockQuantity: stock!,
      ),
    );
  }

  /// Folds a barcode scan's Brand/Weight/Packaging/Country/Ingredients/
  /// Nutrition into one editable block of text — there's no dedicated
  /// catalog field for any of these, so Description is where they surface,
  /// fully visible and editable before the merchant saves.
  static String? _composeEnrichedDescription(ProductLookupResult? prefill) {
    if (prefill == null) return null;
    final lines = <String>[
      if (prefill.brand != null) 'Brand: ${prefill.brand}',
      if (prefill.weight != null) 'Weight: ${prefill.weight}',
      if (prefill.packaging != null) 'Packaging: ${prefill.packaging}',
      if (prefill.country != null) 'Country: ${prefill.country}',
      if (prefill.ingredients != null) 'Ingredients: ${prefill.ingredients}',
      if (prefill.nutritionSummary != null)
        'Nutrition: ${prefill.nutritionSummary}',
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }

  /// True only for the plain "Add from a barcode scan" path — Edit always
  /// supplies [ProductForm.initial] and never a [ProductForm.prefill], and
  /// Duplicate supplies [ProductForm.initial] but no [ProductForm.prefill]
  /// either (see `AddProductPage._initial`'s header comment) — so this is
  /// unambiguous.
  bool get _isImportedFromScan =>
      widget.initial == null && widget.prefill != null;

  @override
  Widget build(BuildContext context) {
    final prefill = widget.prefill;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_isImportedFromScan) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Imported from Open Food Facts',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProductImagePicker(
          uid: widget.uid,
          initialImagePath: widget.initial?.imagePath,
          initialImageUrl: _imagePath == null ? _imageUrl : null,
          onChanged: (path) => setState(() {
            _imagePath = path;
            _imageUrl = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
            label: 'Name',
            hint: 'e.g. Tropical Surf Wax',
            controller: _nameController,
            errorText: _nameError,
            helperText: _isImportedFromScan && prefill?.name != null
                ? 'Auto-filled from Open Food Facts'
                : null),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Description',
          hint: 'Optional',
          controller: _descriptionController,
          maxLines: 3,
          helperText: _isImportedFromScan &&
                  _composeEnrichedDescription(prefill) != null
              ? 'Brand/weight/packaging from Open Food Facts — edit freely'
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                  label: 'SKU',
                  controller: _skuController,
                  errorText: _skuError),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                  label: 'Barcode',
                  hint: 'Optional',
                  controller: _barcodeController,
                  helperText: _isImportedFromScan && prefill?.barcode != null
                      ? 'Auto-filled'
                      : null),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                  label: 'Category',
                  hint: 'Optional',
                  controller: _categoryController,
                  helperText: _isImportedFromScan && prefill?.category != null
                      ? 'Auto-filled'
                      : null),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                  label: 'Unit',
                  hint: 'e.g. pcs',
                  controller: _unitController,
                  errorText: _unitError),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Price',
                controller: _priceController,
                errorText: _priceError,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                label: 'Cost Price',
                controller: _costPriceController,
                errorText: _costPriceError,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Tax %',
                controller: _taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                label: 'Discount %',
                controller: _discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Stock',
                controller: _stockController,
                errorText: _stockError,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                label: 'Low Stock Alert',
                hint: 'Optional',
                controller: _lowStockController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.errorMessage!,
            style: AppTypography.bodySM.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: widget.submitLabel,
          isLoading: widget.isSubmitting,
          onPressed: widget.isSubmitting ? null : _handleSubmit,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
