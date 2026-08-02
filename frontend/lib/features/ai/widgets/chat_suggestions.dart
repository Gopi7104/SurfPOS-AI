import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../demo_data/providers/demo_data_providers.dart';

/// The always-available suggestions — every phrase here matches a real
/// `intent/intentDetector.js` pattern (backend tool or navigation command),
/// so tapping one always resolves to a real answer/action, never a guess
/// sent to OpenRouter. Covers Inventory (real data), navigation, and
/// business-intelligence categories (Reports/Dashboard/Customer — demo-
/// backed where no real ledger exists yet, see `ClientAiToolExecutor`).
const _kAlwaysSuggestions = [
  "Today's Sales",
  'Low Stock',
  'Best Seller',
  'Search Product',
  'Inventory Value',
  'Top Customer',
  'Business Insights',
  'Open Billing',
  'Open Inventory',
  'Open Reports',
  'Open Customers',
];

/// The one suggestion that changes: "Generate Demo Data" is only worth
/// showing when there's no demo dataset yet — see
/// `demoDataControllerProvider`'s header comment. Once one exists, showing
/// it again is more likely to be tapped by accident than intentionally
/// (regenerating replaces the current sample data), so it drops off the
/// list instead.
class ChatSuggestions extends ConsumerWidget {
  const ChatSuggestions({required this.uid, required this.onSelect, super.key});

  final String uid;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDemoData =
        ref.watch(demoDataControllerProvider(uid)).valueOrNull != null;
    final suggestions = [
      ..._kAlwaysSuggestions,
      if (!hasDemoData) 'Generate Demo Data',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.sparkles,
                size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text('Hey Surf,',
                style:
                    AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _SuggestionChip(
                label: suggestion, onTap: () => onSelect(suggestion)),
          ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.bodyMD)),
              const Icon(LucideIcons.arrowUpRight,
                  size: 16, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
