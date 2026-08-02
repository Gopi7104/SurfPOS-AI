import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/tiles/timeline_tile.dart';
import '../models/payment_phase.dart';

/// The animated "what's happening right now" timeline shown while a payment
/// is in flight — Creating Order → Connecting → Processing → (terminal
/// outcome), each row built from the real [PaymentPhase] the app already
/// tracks. No sub-phases are invented: [PaymentPhase] only has these three
/// in-flight states plus a terminal one, so this timeline has exactly four
/// rows, one per phase.
class PaymentProcessingTimeline extends StatelessWidget {
  const PaymentProcessingTimeline({required this.phase, super.key});

  final PaymentPhase phase;

  static const _steps = [
    (PaymentPhase.creatingPayment, 'Creating Order'),
    (PaymentPhase.waitingForCustomer, 'Connecting'),
    (PaymentPhase.paymentProcessing, 'Processing'),
  ];

  int get _currentIndex {
    final index = _steps.indexWhere((step) => step.$1 == phase);
    return index == -1 ? _steps.length : index;
  }

  (String, Color) get _finalStep => switch (phase) {
        PaymentPhase.paymentSuccessful => ('Approved', AppColors.success),
        PaymentPhase.paymentFailed => ('Declined', AppColors.error),
        PaymentPhase.paymentCancelled => ('Cancelled', AppColors.textGrey),
        PaymentPhase.paymentExpired => ('Expired', AppColors.warning),
        PaymentPhase.error => ('Error', AppColors.error),
        _ => ('Approved', AppColors.border),
      };

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final terminal = phase.isTerminal;
    final (finalLabel, finalColor) = _finalStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          TimelineTile(
            title: _steps[i].$2,
            dotColor: i < currentIndex
                ? AppColors.success
                : (i == currentIndex ? AppColors.primary : AppColors.border),
            trailing: i < currentIndex
                ? const Icon(LucideIcons.circleCheck,
                    size: 18, color: AppColors.success)
                : (i == currentIndex
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null),
          ),
        TimelineTile(
          title: finalLabel,
          isLast: true,
          dotColor: terminal ? finalColor : AppColors.border,
          trailing: terminal
              ? Icon(
                  phase == PaymentPhase.paymentSuccessful
                      ? LucideIcons.circleCheck
                      : LucideIcons.circleX,
                  size: 18,
                  color: finalColor,
                )
              : null,
        ),
      ],
    );
  }
}
