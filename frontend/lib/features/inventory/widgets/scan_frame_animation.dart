import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';

/// The barcode scanner's viewfinder — the same bordered frame the scanner
/// already drew, now with an animated sweep line so it reads as "actively
/// scanning" rather than a static rectangle. Purely decorative — detection
/// itself is unaffected, still driven entirely by `MobileScanner`'s own
/// `onDetect`.
class ScanFrameAnimation extends StatefulWidget {
  const ScanFrameAnimation({super.key});

  @override
  State<ScanFrameAnimation> createState() => _ScanFrameAnimationState();
}

class _ScanFrameAnimationState extends State<ScanFrameAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Align(
            alignment: Alignment(0, -1 + 2 * _controller.value),
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.primaryLight,
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
