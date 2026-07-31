import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../models/product_image_exception.dart';
import '../providers/inventory_providers.dart';

/// The Product Image section shared by Add and Edit Product — preview,
/// "Select from Gallery"/"Take Photo"/"Remove Image" actions, loading state
/// while a pick is in flight, and an inline error message on failure.
/// Fully self-contained: owns its own preview/loading/error state and talks
/// to `image_picker` only through [InventoryFormController] (never
/// directly), per docs/22_DEVELOPMENT_ROADMAP.md (Product Image).
class ProductImagePicker extends ConsumerStatefulWidget {
  const ProductImagePicker({
    required this.uid,
    this.initialImagePath,
    required this.onChanged,
    super.key,
  });

  /// The signed-in merchant's uid — resolves the same
  /// `inventoryFormControllerProvider(uid)` instance the rest of the form
  /// already submits through.
  final String uid;

  final String? initialImagePath;

  /// Called whenever the selected image changes (picked or removed) so the
  /// parent `ProductForm` can include the latest path in its
  /// `ProductFormResult` on Save.
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends ConsumerState<ProductImagePicker> {
  late String? _imagePath = widget.initialImagePath;
  bool _isPicking = false;
  String? _errorMessage;

  Future<void> _pick(Future<String?> Function() action) async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final path = await action();
      if (!mounted) return;
      // A null result means the user cancelled the picker — leave whatever
      // image was already selected untouched; that's not an error.
      if (path != null) {
        setState(() => _imagePath = path);
        widget.onChanged(path);
      }
    } on ProductImageException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'Something went wrong selecting the image. Please try again.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _remove() async {
    final notifier =
        ref.read(inventoryFormControllerProvider(widget.uid).notifier);
    final path = await notifier.removeImage();
    if (!mounted) return;
    setState(() {
      _imagePath = path;
      _errorMessage = null;
    });
    widget.onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final notifier =
        ref.read(inventoryFormControllerProvider(widget.uid).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: AppTypography.bodySM
              .copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        _buildPreview(),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_errorMessage!,
              style: AppTypography.bodySM.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isPicking ? null : () => _pick(notifier.pickFromGallery),
                icon: const Icon(LucideIcons.image, size: 18),
                label: const Text('Select from Gallery'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPicking ? null : () => _pick(notifier.takePhoto),
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text('Take Photo'),
              ),
            ),
          ],
        ),
        if (_imagePath != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isPicking ? null : _remove,
              icon: const Icon(LucideIcons.trash2,
                  size: 16, color: AppColors.error),
              label: const Text('Remove Image',
                  style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    if (_isPicking) {
      return const _PreviewBox(child: AppLoadingIndicator());
    }

    final path = _imagePath;
    if (path == null) {
      return const _PreviewBox(
        child: _PlaceholderContent(message: 'No image selected'),
      );
    }

    final file = File(path);
    // A path can outlive its file — the OS reclaims cache/gallery storage, or the file was
    // moved/deleted outside the app. Checking existence up front (rather than only relying on
    // Image.file's errorBuilder) means a stale path never even attempts to decode.
    if (!file.existsSync()) {
      return const _PreviewBox(
        child: _PlaceholderContent(message: 'Image not found'),
      );
    }

    return _PreviewBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // Covers the "exists but isn't a valid/decodable image" case — corrupt file, wrong
          // format, truncated write — without crashing the form.
          errorBuilder: (context, error, stackTrace) =>
              const _PlaceholderContent(message: 'Could not load this image'),
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.disabledSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.image, size: 32, color: AppColors.textGrey),
        const SizedBox(height: AppSpacing.xs),
        Text(message,
            style: AppTypography.caption.copyWith(color: AppColors.textGrey)),
      ],
    );
  }
}
