import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Product Details' Stock Movement section — **UI only**. No backend
/// movement-tracking source exists anywhere in this app (creating one is
/// explicitly out of scope for this phase), so this always renders the
/// "no history yet" placeholder rather than fabricating entries. Kept as
/// its own widget so a future phase can drop real movement data in here
/// without touching `ProductDetailsPage`.
class StockMovementTimeline extends StatelessWidget {
  const StockMovementTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.disabledSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.history, size: 28, color: AppColors.textGrey),
          const SizedBox(height: AppSpacing.sm),
          Text('No movement history yet',
              style:
                  AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Stock changes (sales, restocks, manual adjustments) will show up '
            'here as a timeline in a future update.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
