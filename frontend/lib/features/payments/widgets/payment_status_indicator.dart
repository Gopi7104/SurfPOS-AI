import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../models/payment_phase.dart';

/// Large animated status glyph at the top of the Payment Status screen — a
/// spinner while in progress, a settled icon once [phase] reaches a
/// terminal state. Cross-fades between states via [AnimatedSwitcher] rather
/// than a bespoke animation, matching this app's `AppMotion` conventions.
class PaymentStatusIndicator extends StatelessWidget {
  const PaymentStatusIndicator({required this.phase, super.key});

  final PaymentPhase phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: SizedBox(
        key: ValueKey(phase),
        width: 96,
        height: 96,
        child: phase.isTerminal ? _buildIcon() : _buildSpinner(),
      ),
    );
  }

  Widget _buildSpinner() {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.primarySubtle, shape: BoxShape.circle),
      padding: const EdgeInsets.all(24),
      child: const CircularProgressIndicator(
          strokeWidth: 4, color: AppColors.primary),
    );
  }

  Widget _buildIcon() {
    final (icon, color, background) = switch (phase) {
      PaymentPhase.paymentSuccessful => (
          LucideIcons.circleCheck,
          AppColors.success,
          AppColors.successContainer
        ),
      PaymentPhase.paymentFailed => (
          LucideIcons.circleX,
          AppColors.error,
          AppColors.errorContainer
        ),
      PaymentPhase.paymentCancelled => (
          LucideIcons.circleX,
          AppColors.textGrey,
          AppColors.disabledSurface
        ),
      PaymentPhase.paymentExpired => (
          LucideIcons.clock,
          AppColors.warning,
          AppColors.warningContainer
        ),
      PaymentPhase.error => (
          LucideIcons.triangleAlert,
          AppColors.error,
          AppColors.errorContainer
        ),
      _ => (LucideIcons.creditCard, AppColors.primary, AppColors.primarySubtle),
    };

    return Container(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      padding: const EdgeInsets.all(20),
      child: Icon(icon, size: 48, color: color),
    );
  }
}
