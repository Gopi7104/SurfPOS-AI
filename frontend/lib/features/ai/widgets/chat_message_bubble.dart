import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/chat_message.dart';

/// Icon + label shown on a tool-result bubble — see [ChatToolCategory].
const Map<ChatToolCategory, (IconData, String)> _toolCategoryDisplay = {
  ChatToolCategory.inventory: (LucideIcons.package, 'Inventory'),
  ChatToolCategory.billing: (LucideIcons.receipt, 'Billing'),
  ChatToolCategory.reports: (LucideIcons.barChart3, 'Reports'),
  ChatToolCategory.dashboard: (LucideIcons.layoutDashboard, 'Dashboard'),
  ChatToolCategory.customer: (LucideIcons.users, 'Customers'),
  ChatToolCategory.settings: (LucideIcons.settings, 'Settings'),
};

/// One turn in the SurfAI conversation — user messages are a solid
/// Blueberry bubble, right-aligned. Assistant messages are left-aligned:
/// a plain surface bubble for a normal OpenRouter answer, or — when
/// [ChatMessage.toolCategory] is set — a Blueberry-tinted "tool result" card
/// with a category icon, since that reply came from SurfPOS's own backend
/// data rather than the LLM. Both variants keep the same Markdown
/// rendering, shape, and Copy/Regenerate actions. [showRegenerate] is only
/// ever true for the most recent assistant message (see [SurfAiChatPage]).
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
  // toolCategory is only ever set on an assistant reply in practice (see
  // AiRepositoryImpl.sendMessage) — `!_isUser` here is a defensive guard,
  // not something callers need to think about.
  bool get _isToolResult => !_isUser && message.toolCategory != null;

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
              color: _isUser
                  ? AppColors.primary
                  : (_isToolResult
                      ? AppColors.primarySubtle
                      : AppColors.surface),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(_isUser ? 18 : 4),
                bottomRight: Radius.circular(_isUser ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isToolResult) ...[
                  _ToolCategoryLabel(category: message.toolCategory!),
                  const SizedBox(height: AppSpacing.xs),
                ],
                _isUser
                    ? Text(
                        message.content,
                        style: AppTypography.bodyMD
                            .copyWith(color: AppColors.white),
                      )
                    : MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: _markdownStyle,
                      ),
              ],
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

class _ToolCategoryLabel extends StatelessWidget {
  const _ToolCategoryLabel({required this.category});

  final ChatToolCategory category;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _toolCategoryDisplay[category]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySM.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
