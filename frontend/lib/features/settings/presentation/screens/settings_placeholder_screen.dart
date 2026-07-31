import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../authentication/presentation/screens/login_page.dart';
import '../../../authentication/providers/auth_providers.dart';
import '../../../diagnostics/pages/connection_diagnostics_page.dart';
import '../../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';

/// Placeholder for the Settings tab — Phase 1 builds only the Dashboard and
/// the app shell (see docs/22_DEVELOPMENT_ROADMAP.md); full Settings is
/// explicitly out of scope until a future phase is approved. Log Out and
/// Merchant Onboarding access are kept here (not "Settings functionality")
/// since the app must remain usable/testable without them regressing.
class SettingsPlaceholderScreen extends ConsumerWidget {
  const SettingsPlaceholderScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: const AppTopBar(title: 'Settings'),
      body: SafeArea(
        // Bottom padding clears the shell's floating "New Sale" FAB (AppMainScaffold docks it
        // centered above the bottom nav on every tab) so Log Out is never obscured behind it.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                    user.displayName?.isNotEmpty == true
                        ? user.displayName!
                        : 'Account',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(user.email,
                    style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppSecondaryButton(
                label: 'Merchant Onboarding',
                icon: LucideIcons.building2,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MerchantOnboardingWizardPage()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // TEMPORARY — connectivity-audit tooling, see
              // docs/23_ENVIRONMENT_CONFIGURATION.md. Safe to remove once the
              // Wi-Fi-switching connectivity issue is confirmed resolved.
              AppSecondaryButton(
                label: 'Connection Diagnostics',
                icon: LucideIcons.wifi,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ConnectionDiagnosticsPage()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Log Out',
                icon: LucideIcons.logOut,
                isDestructive: true,
                onPressed: () => _handleLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
