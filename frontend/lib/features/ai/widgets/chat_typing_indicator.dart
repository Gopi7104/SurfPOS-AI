import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Three dots pulsing in sequence — shown in place of the assistant bubble
/// while [AiChatState.isSending] is true.
class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final t = (_controller.value - index * 0.2) % 1.0;
              final scale =
                  0.5 + 0.5 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Transform.scale(
                scale: 0.6 + 0.4 * scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// A left-aligned bubble wrapping [ChatTypingIndicator], matching the shape
/// of an assistant [ChatMessageBubble] so it slots into the same list.
/// [label] shows "SurfAI is checking your business…" while a backend tool
/// looks likely, or "SurfAI is thinking…" otherwise (see
/// `AiChatState.isLikelyToolQuery`) — omit for just the dots.
class ChatTypingBubble extends StatelessWidget {
  const ChatTypingBubble({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChatTypingIndicator(),
            if (label != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                label!,
                style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
