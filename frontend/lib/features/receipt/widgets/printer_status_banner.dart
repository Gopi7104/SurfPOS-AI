import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/printer_status.dart';

/// The Bluetooth printer status banner atop the Receipt screen — a spinner
/// while checking/printing, a success state once printed, or the spec's
/// "No printer connected" prompt with Connect Printer / Skip actions.
class PrinterStatusBanner extends StatelessWidget {
  const PrinterStatusBanner({
    required this.status,
    required this.onConnectPrinter,
    required this.onSkip,
    required this.onRetryPrint,
    super.key,
  });

  final PrinterStatus status;
  final VoidCallback onConnectPrinter;
  final VoidCallback onSkip;
  final VoidCallback onRetryPrint;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      PrinterStatus.unknown || PrinterStatus.checking => _banner(
          icon: LucideIcons.bluetoothSearching,
          color: AppColors.textGrey,
          background: AppColors.disabledSurface,
          message: 'Checking for a paired printer…',
          trailing: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      PrinterStatus.printing => _banner(
          icon: LucideIcons.printer,
          color: AppColors.primary,
          background: AppColors.primarySubtle,
          message: 'Printing receipt…',
          trailing: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      PrinterStatus.printed => _banner(
          icon: LucideIcons.printerCheck,
          color: AppColors.success,
          background: AppColors.successContainer,
          message: 'Receipt printed.',
        ),
      PrinterStatus.connected => _banner(
          icon: LucideIcons.bluetoothConnected,
          color: AppColors.success,
          background: AppColors.successContainer,
          message: 'Printer connected.',
        ),
      PrinterStatus.notConnected => _noPrinterCard(),
      PrinterStatus.error => _banner(
          icon: LucideIcons.printerX,
          color: AppColors.error,
          background: AppColors.errorContainer,
          message: 'Could not reach the printer.',
          trailing:
              TextButton(onPressed: onRetryPrint, child: const Text('Retry')),
        ),
    };
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required Color background,
    required String message,
    Widget? trailing,
  }) {
    return AppCard(
      color: background,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.bodyMD.copyWith(color: color)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _noPrinterCard() {
    return AppCard(
      color: AppColors.disabledSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bluetoothOff,
                  color: AppColors.textGrey, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('No printer connected',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.textGrey)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onConnectPrinter,
                  icon: const Icon(LucideIcons.bluetooth, size: 16),
                  label: const Text('Connect Printer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
