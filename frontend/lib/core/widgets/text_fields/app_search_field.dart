import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Large rounded search bar with an optional trailing barcode-scan action —
/// used on Inventory and the Billing POS screen. See docs/05_FEATURES.md
/// §§ 4, 7 and the BILLING SCREEN design brief.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onScanTap,
    this.autofocus = false,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onScanTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.minTapTarget + 8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          const Icon(LucideIcons.search, size: 20, color: AppColors.textGrey),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: autofocus,
              style: AppTypography.bodyLG,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          if (onScanTap != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Material(
                color: AppColors.primarySubtle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: InkWell(
                  onTap: onScanTap,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      LucideIcons.scanLine,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
