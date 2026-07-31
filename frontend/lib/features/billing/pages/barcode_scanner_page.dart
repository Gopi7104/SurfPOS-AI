import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../inventory/pages/add_product_page.dart';
import '../providers/billing_providers.dart';
import '../widgets/product_not_found_banner.dart';

/// Full-screen live barcode scanner (see docs/22_DEVELOPMENT_ROADMAP.md,
/// Phase 3). Owns the camera/`MobileScannerController` lifecycle and the
/// scan-deduplication timing — both are hardware/widget-lifecycle concerns,
/// not business logic — but every *decoded* code is handed straight to
/// [BillingController.addProductByBarcode]; this widget never decides
/// found/not-found/already-in-cart itself.
class BarcodeScannerPage extends ConsumerStatefulWidget {
  const BarcodeScannerPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends ConsumerState<BarcodeScannerPage> {
  // Continuous scanning + auto-focus are both the platform camera's default behavior in
  // mobile_scanner (DetectionSpeed.normal keeps detecting; there's no separate AF toggle to
  // set) — restricting `formats` is the only tuning this phase's barcode-format list needs.
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

  /// Guards against duplicate scans: set the instant a code is decoded, held through the
  /// inventory lookup, and for a further 1s afterwards — see docs/22_DEVELOPMENT_ROADMAP.md,
  /// Phase 3 ("PERFORMANCE": pause scanner, add product, resume 1s later). The camera stream
  /// itself is never stopped/restarted (that has real hardware latency); detections are just
  /// ignored while this is true.
  bool _isPaused = false;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isPaused) return;

    final code =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      return; // unreadable/empty payload — keep scanning
    }

    setState(() => _isPaused = true);
    try {
      await ref
          .read(billingControllerProvider(widget.uid).notifier)
          .addProductByBarcode(code);
    } finally {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isPaused = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = billingControllerProvider(widget.uid);

    ref.listen(provider.select((s) => s.lastAddedProductName),
        (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Product Added: $next')),
        );
        ref.read(provider.notifier).dismissLastAdded();
      }
    });

    final notFoundBarcode =
        ref.watch(provider.select((s) => s.notFoundBarcode));

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
            onDetect: _handleDetection,
            errorBuilder: (context, error) => _ScannerErrorView(error: error),
          ),
          const IgnorePointer(child: Center(child: _ScanFrame())),
          if (_isPaused)
            const Positioned(
              top: AppSpacing.lg,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 3),
                ),
              ),
            ),
          if (notFoundBarcode != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: ProductNotFoundBanner(
                barcode: notFoundBarcode,
                onSearchManually: () => Navigator.of(context).pop(),
                onAddProduct: () {
                  ref.read(provider.notifier).dismissNotFound();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AddProductPage()),
                  );
                },
                onDismiss: () => ref.read(provider.notifier).dismissNotFound(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

/// Maps mobile_scanner's own exception into the app's plain-language error
/// states — permission-denied and camera-unavailable are both explicitly
/// required to fail gracefully (see docs/22_DEVELOPMENT_ROADMAP.md, Phase 3
/// "ERROR HANDLING").
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
