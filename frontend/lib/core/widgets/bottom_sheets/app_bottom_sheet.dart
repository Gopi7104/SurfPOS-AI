import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../buttons/app_icon_button.dart';

/// Shows a consistently-styled modal bottom sheet: drag handle, optional
/// title row with a close button, rounded top corners, safe-area padding.
/// Every bottom sheet in the app (filters, product quick-actions, payment
/// method picker) goes through this rather than a raw
/// `showModalBottomSheet`. See docs/06_UI_UX_GUIDE.md § 9.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.headingMD),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    size: AppIconButtonSize.sm,
                    onTap: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Flexible(child: builder(sheetContext)),
          ],
        ),
      ),
    ),
  );
}
