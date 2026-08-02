import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:surfpos_ai/features/ai/models/chat_message.dart';
import 'package:surfpos_ai/features/ai/widgets/chat_message_bubble.dart';

Widget _wrap(ChatMessage message) =>
    MaterialApp(home: Scaffold(body: ChatMessageBubble(message: message)));

ChatMessage _message({
  required ChatRole role,
  required String content,
  ChatToolCategory? toolCategory,
}) =>
    ChatMessage(
      id: 'msg_1',
      role: role,
      content: content,
      createdAt: DateTime(2026),
      toolCategory: toolCategory,
    );

void main() {
  testWidgets('a plain assistant reply shows no tool category label',
      (tester) async {
    await tester.pumpWidget(_wrap(
      _message(role: ChatRole.assistant, content: 'Here is some advice.'),
    ));

    expect(find.text('Inventory'), findsNothing);
    expect(find.byIcon(LucideIcons.package), findsNothing);
  });

  testWidgets('a tool-answered reply shows its category icon and label',
      (tester) async {
    await tester.pumpWidget(_wrap(
      _message(
        role: ChatRole.assistant,
        content: '3 products found.',
        toolCategory: ChatToolCategory.inventory,
      ),
    ));

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.byIcon(LucideIcons.package), findsOneWidget);
    expect(find.text('3 products found.'), findsOneWidget);
  });

  testWidgets('each tool category renders its own icon and label',
      (tester) async {
    const expectations = {
      ChatToolCategory.billing: (LucideIcons.receipt, 'Billing'),
      ChatToolCategory.reports: (LucideIcons.barChart3, 'Reports'),
      ChatToolCategory.dashboard: (LucideIcons.layoutDashboard, 'Dashboard'),
      ChatToolCategory.customer: (LucideIcons.users, 'Customers'),
      ChatToolCategory.settings: (LucideIcons.settings, 'Settings'),
    };

    for (final entry in expectations.entries) {
      final (icon, label) = entry.value;
      await tester.pumpWidget(_wrap(
        _message(
            role: ChatRole.assistant, content: 'x', toolCategory: entry.key),
      ));
      expect(find.text(label), findsOneWidget, reason: '${entry.key} label');
      expect(find.byIcon(icon), findsOneWidget, reason: '${entry.key} icon');
    }
  });

  testWidgets('a user message never shows a tool category label even if set',
      (tester) async {
    await tester.pumpWidget(_wrap(
      _message(
        role: ChatRole.user,
        content: 'show products',
        toolCategory: ChatToolCategory.inventory,
      ),
    ));

    // toolCategory is only ever set on assistant replies in practice, but the
    // bubble's own _isUser check must still win if it somehow were set.
    expect(find.text('show products'), findsOneWidget);
    expect(find.text('Inventory'), findsNothing);
    expect(find.byIcon(LucideIcons.package), findsNothing);
  });
}
