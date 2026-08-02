import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../controllers/receipt_controller.dart';
import '../models/receipt_model.dart';

/// The Receipt's large action tiles — Print, Share, Download PDF, Send
/// Email, Send WhatsApp, and a disabled Refund placeholder. "New Sale"
/// stays its own full-width sticky button below this grid (see
/// `ReceiptPage`) rather than a same-size tile here — it's the single most
/// important next action after a completed sale, so it keeps the most
/// prominent affordance instead of competing visually with six others.
/// "Download PDF" reuses [ReceiptController.sharePdf] — there is no
/// separate direct-to-disk API, and the OS share sheet it opens already
/// offers "Save to Files"/"Save to device".
class ReceiptActionGrid extends StatelessWidget {
  const ReceiptActionGrid(
      {required this.receipt,
      required this.notifier,
      required this.isSharing,
      super.key});

  final ReceiptModel receipt;
  final ReceiptController notifier;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        _ActionButton(
          icon: LucideIcons.printer,
          label: 'Print',
          onTap: () => notifier.printReceipt(receipt),
        ),
        _ActionButton(
          icon: LucideIcons.share2,
          label: 'Share',
          isLoading: isSharing,
          onTap: isSharing ? null : () => notifier.sharePdf(receipt),
        ),
        _ActionButton(
          icon: LucideIcons.fileDown,
          label: 'Download PDF',
          isLoading: isSharing,
          onTap: isSharing ? null : () => notifier.sharePdf(receipt),
        ),
        _ActionButton(
          icon: LucideIcons.mail,
          label: 'Send Email',
          isLoading: isSharing,
          onTap: isSharing ? null : () => notifier.shareViaEmail(receipt),
        ),
        _ActionButton(
          icon: LucideIcons.messageCircle,
          label: 'Send WhatsApp',
          isLoading: isSharing,
          onTap: isSharing ? null : () => notifier.shareViaWhatsApp(receipt),
        ),
        const _ActionButton(
          icon: LucideIcons.undo2,
          label: 'Refund',
          badge: StatusChip(label: 'Coming Soon'),
          enabled: false,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.badge,
    this.isLoading = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
              boxShadow: enabled ? AppShadows.subtle : null,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(height: AppSpacing.xs),
                Text(label,
                    style: AppTypography.bodySM
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  badge!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
