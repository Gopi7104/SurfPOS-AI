import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';

/// A compact label/value row with a trailing Edit button — Merchant
/// Profile's Business Name/Email/Phone/Address/Country/Tax Number/
/// Business Type each render through this one card rather than a
/// full-screen text field per field.
class EditableInfoCard extends StatelessWidget {
  const EditableInfoCard({
    required this.label,
    required this.value,
    required this.onEdit,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
