import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/chat_message.dart';

/// One turn in the SurfAI conversation — user messages are a solid
/// Blueberry bubble, right-aligned; assistant messages are a plain surface
/// bubble, left-aligned, with Markdown rendering (lists, tables, code
/// blocks) and a Copy action. [showRegenerate] is only ever true for the
/// most recent assistant message (see [SurfAiChatPage]).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    this.showRegenerate = false,
    this.onRegenerate,
    super.key,
  });

  final ChatMessage message;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;

  bool get _isUser => message.role == ChatRole.user;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: _isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(_isUser ? 18 : 4),
                bottomRight: Radius.circular(_isUser ? 4 : 18),
              ),
            ),
            child: _isUser
                ? Text(
                    message.content,
                    style:
                        AppTypography.bodyMD.copyWith(color: AppColors.white),
                  )
                : MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: _markdownStyle,
                  ),
          ),
          if (!_isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                      icon: LucideIcons.copy, onTap: () => _copy(context)),
                  if (showRegenerate && onRegenerate != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _ActionIcon(
                        icon: LucideIcons.repeat2, onTap: onRegenerate!),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  MarkdownStyleSheet get _markdownStyle => MarkdownStyleSheet(
        p: AppTypography.bodyMD,
        strong: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w700),
        em: AppTypography.bodyMD.copyWith(fontStyle: FontStyle.italic),
        listBullet: AppTypography.bodyMD,
        code: AppTypography.bodySM.copyWith(
          fontFamily: 'monospace',
          backgroundColor: AppColors.disabledSurface,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.secondarySubtle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        tableBorder: TableBorder.all(color: AppColors.border),
        tableHead: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w700),
        tableBody: AppTypography.bodySM,
        tableCellsPadding: const EdgeInsets.all(AppSpacing.xs),
      );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, size: 14, color: AppColors.textGrey),
      ),
    );
  }
}
