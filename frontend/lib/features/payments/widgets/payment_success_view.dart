import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/app_card.dart';

/// The "Success Screen" beat — a big green checkmark that pops in with a
/// subtle confetti burst, "Payment Approved", the amount, and the sale's
/// identifiers. Purely presentational: [PaymentStatusPage] holds this on
/// screen for a moment before its already-decided navigation to
/// [ReceiptPage] fires (see that page's header comment) — this widget
/// itself has no timers or navigation of its own.
class PaymentSuccessView extends StatefulWidget {
  const PaymentSuccessView({
    required this.amount,
    required this.reference,
    required this.transactionId,
    required this.merchantName,
    required this.completedAt,
    super.key,
  });

  final double? amount;
  final String? reference;
  final String? transactionId;
  final String merchantName;
  final DateTime completedAt;

  @override
  State<PaymentSuccessView> createState() => _PaymentSuccessViewState();
}

class _PaymentSuccessViewState extends State<PaymentSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) =>
                    CustomPaint(painter: _ConfettiPainter(_controller.value)),
                child: const SizedBox.expand(),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check,
                        size: 44, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Payment Approved',
            style: AppTypography.headingLG.copyWith(color: AppColors.success)),
        const SizedBox(height: AppSpacing.sm),
        if (widget.amount != null)
          CountUpNumber(
            value: widget.amount!,
            formatter: (v) => '\$${v.toStringAsFixed(2)}',
            style: AppTypography.numberXL,
          ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(label: 'Reference', value: widget.reference),
              _DetailRow(label: 'Transaction ID', value: widget.transactionId),
              _DetailRow(label: 'Merchant', value: widget.merchantName),
              _DetailRow(
                  label: 'Date', value: _formatDateTime(widget.completedAt)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
          Flexible(
            child: Text(
              value ?? '—',
              style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small, on-brand confetti burst (not a rainbow) — a fixed, seeded set of
/// particles that fall and fade out once as [progress] goes 0→1. Deliberately
/// self-contained (no new pubspec dependency) and subtle per the brief.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);

  final double progress;

  static final _particles = List.generate(14, (i) {
    final random = Random(i * 7919);
    return (
      angle: random.nextDouble() * pi * 2,
      distance: 50 + random.nextDouble() * 40,
      size: 3.0 + random.nextDouble() * 3,
      color: [
        AppColors.primary,
        AppColors.success,
        AppColors.warning,
        AppColors.secondary,
      ][i % 4],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (final particle in _particles) {
      final travel = particle.distance * progress;
      final dx = cos(particle.angle) * travel;
      final dy = sin(particle.angle) * travel + (40 * progress * progress);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: fade * 0.8);
      canvas.drawCircle(center + Offset(dx, dy), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
