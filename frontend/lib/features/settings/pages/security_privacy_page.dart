import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/settings_data.dart';

/// Replaces the old dead "Privacy Settings" tile. Explains, honestly, the
/// real current state of every Security preference on Settings Home
/// (Biometric Login/PIN Lock/Auto Logout/Session Timeout are genuinely
/// persisted — see [SettingsController] — but not enforced anywhere yet),
/// what "Screen Privacy" would even mean, and exactly what each would
/// require to become real: a new package (`local_auth`) and a gate added
/// inside Authentication — deliberately out of scope for a Settings-only
/// activation pass, per this phase's own hard rule not to touch
/// Authentication's business logic.
class SecurityPrivacyPage extends StatelessWidget {
  const SecurityPrivacyPage({required this.settings, super.key});

  final SettingsData settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
          title: 'Security & Privacy',
          onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These preferences are saved on this device but don\'t yet '
                  'restrict access to the app — turning one on records your '
                  'choice for when real enforcement is added, it doesn\'t '
                  'lock anything today.',
                  style: AppTypography.bodyMD,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusRow(
            icon: LucideIcons.fingerprint,
            title: 'Biometric Login',
            enabled: settings.biometricLoginEnabled,
            requirement:
                'Requires adding the local_auth package and a sign-in gate — not present in this app yet.',
          ),
          _StatusRow(
            icon: LucideIcons.keyRound,
            title: 'PIN Lock',
            enabled: settings.pinLockEnabled,
            requirement: settings.pinCode == null
                ? 'No PIN has been set.'
                : 'A PIN is saved, but nothing in the app currently checks it on launch.',
          ),
          _StatusRow(
            icon: LucideIcons.logOut,
            title: 'Auto Logout',
            enabled: settings.autoLogoutEnabled,
            requirement:
                'Session timeout is set to ${settings.sessionTimeoutMinutes} min, but idle time isn\'t tracked yet.',
          ),
          const _StatusRow(
            icon: LucideIcons.eyeOff,
            title: 'Screen Privacy',
            enabled: false,
            alwaysUnavailable: true,
            requirement:
                'Hiding app content in the recent-apps switcher/blocking screenshots requires a native platform integration not built yet.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connected Devices',
                    style: AppTypography.bodySM
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This app only tracks the session on this device — there is no '
                  'multi-device session list to manage.',
                  style:
                      AppTypography.bodySM.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.requirement,
    this.alwaysUnavailable = false,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final String requirement;
  final bool alwaysUnavailable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title,
                      style: AppTypography.bodyMD
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                StatusChip(
                  label: alwaysUnavailable
                      ? 'Not built yet'
                      : (enabled ? 'On (unenforced)' : 'Off'),
                  tone: alwaysUnavailable
                      ? StatusTone.neutral
                      : (enabled ? StatusTone.warning : StatusTone.neutral),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(requirement,
                style:
                    AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}
