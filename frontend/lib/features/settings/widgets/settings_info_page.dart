import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';

/// The shared "informative configuration page" every genuinely-unavailable
/// Settings feature opens instead of a dead `Coming Soon` snackbar (Help
/// Center, FAQ, Privacy Policy, Terms, Language, Security & Privacy, View
/// Logs, ...). Explains what the feature is, why it isn't available today,
/// and — via [requirements] — exactly what would need to be added (a
/// package, a backend endpoint, hardware support) to enable it for real.
/// [actionLabel]/[onAction] surface a real action when one exists (e.g.
/// "Email Support") rather than leaving the page purely informational.
///
/// One reusable widget, not a bespoke page per feature — every "why isn't
/// this available" screen in Settings should look and read the same way.
class SettingsInfoPage extends StatelessWidget {
  const SettingsInfoPage({
    required this.title,
    required this.summary,
    this.icon = LucideIcons.info,
    this.requirements = const [],
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final IconData icon;

  /// One or two sentences: what this feature is and its current status.
  final String summary;

  /// Bullet points explaining what's required to enable this for real
  /// (e.g. "Requires the `local_auth` package" / "No backend endpoint
  /// exists yet" / "Requires a paired Bluetooth printer"). Empty when the
  /// page is purely explanatory (e.g. a published policy doesn't exist).
  final List<String> requirements;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppTopBar(title: title, onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(summary, style: AppTypography.bodyMD),
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('What this needs',
                      style: AppTypography.bodySM
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final requirement in requirements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(LucideIcons.circleDot,
                                size: 12, color: AppColors.textGrey),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(requirement,
                                style: AppTypography.bodySM
                                    .copyWith(color: AppColors.textGrey)),
                          ),
                        ],
                      ),
                    ),
                ],
                if (onAction != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                      label: actionLabel ?? 'Continue', onPressed: onAction),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
