import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/printer_config.dart';

/// The Printer section's connection summary — connected printer name, or
/// the spec's own required "No printer connected" copy. Mirrors Receipt's
/// `PrinterStatusBanner` look (icon + tinted background + message) but is
/// this module's own widget, since it reflects [PrinterRepository]'s
/// connection, not Receipt's.
class PrinterStatusCard extends StatelessWidget {
  const PrinterStatusCard({
    required this.status,
    this.connectedPrinterName,
    super.key,
  });

  final PrinterConnectionStatus status;
  final String? connectedPrinterName;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background, message) = switch (status) {
      PrinterConnectionStatus.checking => (
          LucideIcons.bluetoothSearching,
          AppColors.textGrey,
          AppColors.disabledSurface,
          'Checking for a paired printer…',
        ),
      PrinterConnectionStatus.connected => (
          LucideIcons.bluetooth,
          AppColors.success,
          AppColors.successContainer,
          connectedPrinterName ?? 'Printer connected',
        ),
      PrinterConnectionStatus.notConnected => (
          LucideIcons.bluetoothOff,
          AppColors.textGrey,
          AppColors.disabledSurface,
          'No printer connected',
        ),
      PrinterConnectionStatus.testing => (
          LucideIcons.printer,
          AppColors.primary,
          AppColors.primarySubtle,
          'Printing test page…',
        ),
      PrinterConnectionStatus.error => (
          LucideIcons.circleAlert,
          AppColors.error,
          AppColors.errorContainer,
          'Connection error',
        ),
    };

    return AppCard(
      color: background,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.bodyMD
                    .copyWith(fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}
