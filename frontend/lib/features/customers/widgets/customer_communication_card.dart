import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';

/// Communication actions — Call/SMS/WhatsApp use the customer's real
/// [phone]; Email uses the real [email] (nullable — this module never
/// requires one). Each action is only enabled when the underlying contact
/// field actually exists; otherwise it renders disabled with "Coming
/// Soon", per the CRM redesign brief. Uses the same `launchUrl` +
/// try/catch + snackbar-fallback pattern already established by
/// `MerchantOnboardingWizardPage._handleOpenKybLink` — just a `tel:`/
/// `sms:`/`mailto:`/`https://wa.me/` URI instead of a `https:` one; no new
/// package, no new backend/database field, no persisted state.
class CustomerCommunicationCard extends StatelessWidget {
  const CustomerCommunicationCard({required this.phone, this.email, super.key});

  final String phone;
  final String? email;

  Future<void> _launch(BuildContext context, Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open the app for this action.')),
      );
    }
  }

  String get _digitsOnlyPhone => phone.replaceAll(RegExp(r'[^\d+]'), '');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Communication'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.2,
          children: [
            _ActionTile(
              icon: LucideIcons.phone,
              label: 'Call',
              onTap: () => _launch(context, Uri(scheme: 'tel', path: phone)),
            ),
            _ActionTile(
              icon: LucideIcons.messageSquare,
              label: 'SMS',
              onTap: () => _launch(context, Uri(scheme: 'sms', path: phone)),
            ),
            _ActionTile(
              icon: LucideIcons.messageCircle,
              label: 'WhatsApp',
              onTap: () => _launch(
                  context, Uri.parse('https://wa.me/$_digitsOnlyPhone')),
            ),
            _ActionTile(
              icon: LucideIcons.mail,
              label: 'Email',
              onTap: email == null
                  ? null
                  : () => _launch(context, Uri(scheme: 'mailto', path: email)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _enabled
                  ? AppColors.primarySubtle
                  : AppColors.disabledSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon,
                size: 16,
                color: _enabled ? AppColors.primary : AppColors.disabledText),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodySM
                        .copyWith(fontWeight: FontWeight.w700)),
                if (!_enabled)
                  Text('Coming Soon',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.disabledText,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
