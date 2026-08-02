import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/product_lookup_result.dart';
import '../providers/inventory_providers.dart';
import '../widgets/already_in_inventory_banner.dart';
import '../widgets/lookup_error_banner.dart';
import '../widgets/lookup_not_found_banner.dart';
import '../widgets/scan_frame_animation.dart';
import 'add_product_page.dart';
import 'product_details_page.dart';

/// Full-screen live barcode scanner for Product Onboarding — camera
/// mechanics mirror Billing's own `BarcodeScannerPage` (same hardware/
/// widget-lifecycle concerns), but every decoded code is handed to
/// [ProductLookupController.lookup] instead of Billing's cart lookup: this
/// widget never decides existing/found/not-found/error itself, and it never
/// touches Billing's controller or repository.
class ProductBarcodeScannerPage extends ConsumerStatefulWidget {
  const ProductBarcodeScannerPage({super.key});

  @override
  ConsumerState<ProductBarcodeScannerPage> createState() =>
      _ProductBarcodeScannerPageState();
}

class _ProductBarcodeScannerPageState
    extends ConsumerState<ProductBarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  /// Set the instant a code is decoded and held until the merchant resumes
  /// (via "Try Again"/"Scan Again", or by navigating away) — unlike
  /// Billing's scanner, a lookup result here needs to be read and acted on,
  /// not auto-dismissed after a second.
  bool _isPaused = false;

  Future<void> _handleDetection(BarcodeCapture capture, String uid) async {
    if (_isPaused) return;

    final code =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isPaused = true);
    await ref.read(productLookupControllerProvider(uid).notifier).lookup(code);
  }

  void _resume(String uid) {
    ref.read(productLookupControllerProvider(uid).notifier).reset();
    setState(() => _isPaused = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final provider = productLookupControllerProvider(uid);
    final lookupState = ref.watch(provider);

    ref.listen(provider.select((s) => s.result), (previous, next) {
      if (next == null) return;
      ref.read(provider.notifier).reset();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AddProductPage(prefill: next)),
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: const Text('Scan Barcode'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: 'Toggle torch',
                onPressed: state.torchState == TorchState.unavailable
                    ? null
                    : _controller.toggleTorch,
                icon: Icon(torchOn ? LucideIcons.zap : LucideIcons.zapOff),
              );
            },
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _controller.switchCamera,
            icon: const Icon(LucideIcons.switchCamera),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) => _handleDetection(capture, uid),
            errorBuilder: (context, error) => _ScannerErrorView(error: error),
          ),
          const IgnorePointer(child: Center(child: ScanFrameAnimation())),
          if (lookupState.isLoading)
            Positioned(
              top: AppSpacing.lg,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Looking up product…',
                          style: AppTypography.bodySM
                              .copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (lookupState.existingProduct != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: AlreadyInInventoryBanner(
                product: lookupState.existingProduct!,
                onViewProduct: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                        productId: lookupState.existingProduct!.id),
                  ),
                ),
                onScanAgain: () => _resume(uid),
              ),
            ),
          if (lookupState.notFoundBarcode != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: LookupNotFoundBanner(
                barcode: lookupState.notFoundBarcode!,
                onEnterManually: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => AddProductPage(
                      prefill: ProductLookupResult(
                          barcode: lookupState.notFoundBarcode!),
                    ),
                  ),
                ),
                onTryAgain: () => _resume(uid),
              ),
            ),
          if (lookupState.errorMessage != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: LookupErrorBanner(
                message: lookupState.errorMessage!,
                onRetry: () => _resume(uid),
              ),
            ),
        ],
      ),
    );
  }
}

/// Maps mobile_scanner's own exception into the app's plain-language error
/// states — permission-denied and camera-unavailable both fail gracefully
/// (see "ERROR HANDLING": Camera permission denied), mirroring Billing's own
/// `_ScannerErrorView`.
class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error});

  final MobileScannerException error;

  String get _message => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Camera permission is denied. Enable camera access in your device Settings to scan barcodes.',
        MobileScannerErrorCode.unsupported =>
          'The camera is unavailable on this device.',
        _ => 'Could not start the camera. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cameraOff,
                  size: 48, color: AppColors.white),
              const SizedBox(height: AppSpacing.md),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMD.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Close',
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
