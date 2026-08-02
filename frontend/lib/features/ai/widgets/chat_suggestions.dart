import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// The "Hey Surf, ..." example-prompt list shown before the first message
/// of a conversation — see docs/16_AI_MODULE.md / the SurfAI chat brief.
const kSurfAiSuggestions = [
  'What sold the most today?',
  'Which products are low stock?',
  'Add a new product',
  "Explain today's revenue",
  'Help me onboard a merchant',
];

class ChatSuggestions extends StatelessWidget {
  const ChatSuggestions({required this.onSelect, super.key});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
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
        for (final suggestion in kSurfAiSuggestions)
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
