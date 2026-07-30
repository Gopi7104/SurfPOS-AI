import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/dialogs/error_banner.dart';
import '../../data/models/merchant_application.dart';

/// Shown once an application exists (right after submit, or on reopening
/// the wizard with one already tracked) — status, the Surfboard-hosted KYB
/// link (while still relevant), and a way to check for updates.
/// Presentation-only: [onOpenKybLink] is provided by the caller so this
/// widget never imports `url_launcher` itself, keeping platform-channel
/// code out of the presentation layer.
class ResultStepScreen extends StatelessWidget {
  const ResultStepScreen({
    required this.application,
    this.onRefresh,
    this.onOpenKybLink,
    this.isRefreshing = false,
    this.errorMessage,
    super.key,
  });

  final MerchantApplication application;
  final VoidCallback? onRefresh;

  /// Called with the KYB URL when "Open KYB Application" is tapped.
  final ValueChanged<String>? onOpenKybLink;
  final bool isRefreshing;
  final String? errorMessage;

  bool get _showKybLink =>
      application.applicationUrl != null &&
      (application.applicationStatus == ApplicationStatus.applicationInitiated ||
          application.applicationStatus == ApplicationStatus.applicationPendingInformation);

  @override
  Widget build(BuildContext context) {
    final isLive = application.applicationStatus == ApplicationStatus.merchantCreated;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              isLive ? LucideIcons.checkCircle : LucideIcons.fileText,
              size: 56,
              color: isLive ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            application.applicationStatus.label,
            textAlign: TextAlign.center,
            style: AppTypography.headingMD,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Application ID: ${application.applicationId}',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (errorMessage != null) ...[
            ErrorBanner(message: errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_showKybLink) ...[
            AppPrimaryButton(
              label: 'Open KYB Application',
              icon: LucideIcons.externalLink,
              onPressed: () => onOpenKybLink?.call(application.applicationUrl!),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Copy link',
              icon: LucideIcons.copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: application.applicationUrl!));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (isLive) ...[
            Text(
              'Merchant ID: ${application.merchantId}',
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
            ),
            Text(
              'Store ID: ${application.storeId}',
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSecondaryButton(
            label: 'Refresh status',
            icon: LucideIcons.refreshCw,
            onPressed: isRefreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}
