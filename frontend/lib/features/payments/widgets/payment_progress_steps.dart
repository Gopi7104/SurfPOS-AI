import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/payment_phase.dart';

enum _Step { creating, waiting, processing, done }

/// The four-step Checkout journey (Creating Payment → Waiting For Payment →
/// Processing → Done), each step marked complete/current/pending from
/// [phase]. A failure ([PaymentPhase.declined]/[cancelled]/[timedOut]/[error])
/// still marks every step up to "Processing" complete — the failure itself
/// is communicated by [PaymentStatusIndicator], not by regressing a step.
class PaymentProgressSteps extends StatelessWidget {
  const PaymentProgressSteps({required this.phase, super.key});

  final PaymentPhase phase;

  _Step get _currentStep => switch (phase) {
        PaymentPhase.creatingPayment => _Step.creating,
        PaymentPhase.waitingForPayment => _Step.waiting,
        PaymentPhase.processing => _Step.processing,
        _ => _Step.done,
      };

  @override
  Widget build(BuildContext context) {
    final steps = [
      (_Step.creating, 'Creating Payment'),
      (_Step.waiting, 'Waiting For Payment'),
      (_Step.processing, 'Processing'),
      (_Step.done, phase.isTerminal ? _terminalLabel : 'Done'),
    ];
    final currentIndex = _currentStep.index;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
              child: _StepDot(
                  label: steps[i].$2, state: _stateFor(i, currentIndex))),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < currentIndex ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }

  String get _terminalLabel => switch (phase) {
        PaymentPhase.approved => 'Approved',
        PaymentPhase.declined => 'Declined',
        PaymentPhase.cancelled => 'Cancelled',
        PaymentPhase.timedOut => 'Timed Out',
        PaymentPhase.error => 'Error',
        _ => 'Done',
      };

  _StepState _stateFor(int index, int currentIndex) {
    if (index < currentIndex) return _StepState.complete;
    if (index == currentIndex) return _StepState.current;
    return _StepState.pending;
  }
}

enum _StepState { complete, current, pending }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.complete || _StepState.current => AppColors.primary,
      _StepState.pending => AppColors.border,
    };

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: state == _StepState.complete
              ? const Icon(LucideIcons.check, size: 14, color: AppColors.white)
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: state == _StepState.pending
                ? AppColors.textGrey
                : AppColors.textDark,
            fontWeight:
                state == _StepState.current ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
