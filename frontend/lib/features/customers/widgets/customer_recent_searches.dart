import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Recent search terms for this screen session — purely ephemeral,
/// in-memory UI convenience state held by [CustomerListPage] itself
/// (never persisted to any repository/local storage, never a new provider
/// or database field): it resets the moment the page is disposed. Renders
/// nothing when [terms] is empty.
class CustomerRecentSearches extends StatelessWidget {
  const CustomerRecentSearches({
    required this.terms,
    required this.onSelect,
    required this.onClear,
    super.key,
  });

  final List<String> terms;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: onClear,
                child: Text('Clear',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final term in terms)
                _RecentChip(term: term, onTap: () => onSelect(term)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.term, required this.onTap});

  final String term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.disabledSurface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.history,
                  size: 12, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(term, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
