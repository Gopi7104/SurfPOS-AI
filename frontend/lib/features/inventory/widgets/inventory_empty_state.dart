import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';

/// A richer empty-state treatment for Inventory only (No Products/No
/// Search Results/No Low Stock/No Barcode Match) — a soft two-tone icon
/// backdrop instead of the shared `EmptyState`'s single flat circle, so
/// Inventory's premium redesign doesn't ride on (or alter) the plainer
/// component every other feature still uses.
class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({
    required this.title,
    required this.message,
    this.icon = LucideIcons.package,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 104,
              width: 104,
              decoration: const BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  height: 72,
                  width: 72,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center, style: AppTypography.headingMD),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                  label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
