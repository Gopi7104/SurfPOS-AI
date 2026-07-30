import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../authentication/presentation/screens/login_page.dart';
import '../../../authentication/providers/auth_providers.dart';

/// Placeholder for the real Dashboard (screen 5/26 of the design brief,
/// not yet built) — exists purely as the post-auth destination so the
/// authentication module has somewhere real to land and a working Logout
/// path. Replace the body with the actual Dashboard once that screen is
/// designed; the Logout wiring below should carry over unchanged.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.displayName?.isNotEmpty == true
                      ? 'Welcome, ${user!.displayName}!'
                      : 'Welcome!',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLG,
                ),
                if (user != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.textGrey),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                AppSecondaryButton(
                  label: 'Log Out',
                  icon: LucideIcons.logOut,
                  expand: false,
                  isDestructive: true,
                  onPressed: () => _handleLogout(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
