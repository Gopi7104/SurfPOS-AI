import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_info_tile.dart';
import '../widgets/settings_navigation_tile.dart';
import '../widgets/settings_section.dart';

/// The About page — Version/Build/Environment (real, reused from
/// [DiagnosticsController] rather than a second `PackageInfo` call),
/// Licenses (real, Flutter's own `showLicensePage`), and Developer/GitHub/
/// Report a Bug/Release Notes/Contact Support links. Per the redesign
/// brief, "only link to pages that already exist" — GitHub/Report a Bug/
/// Release Notes point at this project's real, committed repository
/// (`github.com/Gopi7104/SurfPOS-AI`, confirmed via `git remote`) and
/// Contact Support/Developer point at the project owner's email already
/// published in this repo's own `README.md`/`docs/12_README.md`. Privacy
/// Policy/Terms/Website have no real published page to link to yet, so
/// they're shown as honest status rows rather than a fake link.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  /// Reused by Settings Home's Support section (Report Bug/Feature
  /// Request) so the URL/email exist in exactly one place.
  static const repositoryUrl = 'https://github.com/Gopi7104/SurfPOS-AI';
  static const supportEmailAddress = 'velan87600@gmail.com';

  Future<void> _launch(BuildContext context, Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final diagnostics =
        ref.watch(diagnosticsControllerProvider(uid)).valueOrNull;

    return Scaffold(
      appBar:
          AppTopBar(title: 'About', onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(LucideIcons.store,
                      color: AppColors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('SurfPOS AI', style: AppTypography.headingMD),
                const SizedBox(height: 2),
                Text(
                  'AI-powered mobile-first cloud POS for small retailers',
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.bodySM.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsSection(title: 'Version', children: [
            SettingsInfoTile(label: 'Version', value: diagnostics?.appVersion),
            SettingsInfoTile(
                label: 'Build Number', value: diagnostics?.buildNumber),
            SettingsInfoTile(
                label: 'Environment', value: diagnostics?.environment),
          ]),
          const SizedBox(height: AppSpacing.sm + 4),
          SettingsSection(title: 'Legal', children: [
            SettingsNavigationTile(
              title: 'Licenses',
              icon: LucideIcons.scrollText,
              onTap: () => showLicensePage(
                  context: context, applicationName: 'SurfPOS AI'),
            ),
            const SettingsInfoTile(
                label: 'Privacy Policy', value: 'Not published yet'),
            const SettingsInfoTile(
                label: 'Terms of Service', value: 'Not published yet'),
          ]),
          const SizedBox(height: AppSpacing.sm + 4),
          SettingsSection(title: 'Links', children: [
            SettingsNavigationTile(
              title: 'GitHub Repository',
              icon: LucideIcons.gitBranch,
              onTap: () => _launch(context, Uri.parse(repositoryUrl)),
            ),
            SettingsNavigationTile(
              title: 'Release Notes',
              icon: LucideIcons.fileText,
              onTap: () => _launch(context,
                  Uri.parse('$repositoryUrl/blob/main/docs/11_CHANGELOG.md')),
            ),
            SettingsNavigationTile(
              title: 'Report a Bug',
              icon: LucideIcons.bug,
              onTap: () =>
                  _launch(context, Uri.parse('$repositoryUrl/issues/new')),
            ),
            const SettingsInfoTile(
                label: 'Website', value: 'Not published yet'),
          ]),
          const SizedBox(height: AppSpacing.sm + 4),
          SettingsSection(title: 'Contact', children: [
            const SettingsInfoTile(label: 'Developer', value: 'Velan'),
            SettingsNavigationTile(
              title: 'Contact Support',
              icon: LucideIcons.mail,
              valueLabel: supportEmailAddress,
              onTap: () => _launch(
                context,
                Uri(
                    scheme: 'mailto',
                    path: supportEmailAddress,
                    query: 'subject=SurfPOS AI Support'),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
