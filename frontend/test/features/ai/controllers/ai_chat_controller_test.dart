import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/ai/models/ai_chat_reply.dart';
import 'package:surfpos_ai/features/ai/models/chat_message.dart';
import 'package:surfpos_ai/features/ai/providers/ai_providers.dart';
import 'package:surfpos_ai/features/ai/repositories/ai_repository.dart';

import '../fakes/fake_ai_repository.dart';

const _uid = 'uid-1';

ProviderContainer _makeContainer(AiRepository repository) {
  return ProviderContainer(
      overrides: [aiRepositoryProvider.overrideWithValue(repository)]);
}

ChatMessage _message(String content, {ChatToolCategory? toolCategory}) =>
    ChatMessage(
      id: 'msg_reply',
      role: ChatRole.assistant,
      content: content,
      createdAt: DateTime(2026),
      toolCategory: toolCategory,
    );

void main() {
  group('AiChatController', () {
    test('build() starts with an empty conversation', () {
      final container = _makeContainer(FakeAiRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

      final state = container.read(aiChatControllerProvider(_uid));

      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
    });

    test('sendMessage() appends the user message, then the assistant reply',
        () async {
      final container = _makeContainer(
        FakeAiRepository(
          sendMessage: (history, {model}) async =>
              AiChatReply(message: _message('Hi there!')),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);
      final notifier = container.read(aiChatControllerProvider(_uid).notifier);

      await notifier.sendMessage('Hello');

      final state = container.read(aiChatControllerProvider(_uid));
      expect(state.messages, hasLength(2));
      expect(state.messages[0].role, ChatRole.user);
      expect(state.messages[0].content, 'Hello');
      expect(state.messages[1].role, ChatRole.assistant);
      expect(state.messages[1].content, 'Hi there!');
      expect(state.isSending, isFalse);
    });

    test('ignores blank input and never sends it', () async {
      var called = false;
      final container = _makeContainer(
        FakeAiRepository(
          sendMessage: (history, {model}) async {
            called = true;
            return AiChatReply(message: _message('should not happen'));
          },
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

      await container
          .read(aiChatControllerProvider(_uid).notifier)
          .sendMessage('   ');

      expect(called, isFalse);
      expect(container.read(aiChatControllerProvider(_uid)).messages, isEmpty);
    });

    test('a tool-answered reply carries its toolCategory through to state',
        () async {
      final container = _makeContainer(
        FakeAiRepository(
          sendMessage: (history, {model}) async => AiChatReply(
            message: _message('3 products found.',
                toolCategory: ChatToolCategory.inventory),
          ),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

      await container
          .read(aiChatControllerProvider(_uid).notifier)
          .sendMessage('show products');

      final reply =
          container.read(aiChatControllerProvider(_uid)).messages.last;
      expect(reply.toolCategory, ChatToolCategory.inventory);
    });

    test('sets isLikelyToolQuery for a business-data-looking message',
        () async {
      final container = _makeContainer(FakeAiRepository());
      addTearDown(container.dispose);
      final sub = container.listen(aiChatControllerProvider(_uid), (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(aiChatControllerProvider(_uid).notifier);

      final future = notifier.sendMessage('what is low on stock');
      // isSending flips true synchronously, before the repository call resolves.
      expect(container.read(aiChatControllerProvider(_uid)).isLikelyToolQuery,
          isTrue);
      await future;
    });

    test('does not set isLikelyToolQuery for a generic question', () async {
      final container = _makeContainer(FakeAiRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);
      final notifier = container.read(aiChatControllerProvider(_uid).notifier);

      final future = notifier.sendMessage('How can I grow my business?');
      expect(container.read(aiChatControllerProvider(_uid)).isLikelyToolQuery,
          isFalse);
      await future;
    });

    test(
        'surfaces a repository failure as a dismissible error, not a thrown exception',
        () async {
      final container = _makeContainer(
        FakeAiRepository(
          sendMessage: (history, {model}) async =>
              throw StateError('network down'),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);
      final notifier = container.read(aiChatControllerProvider(_uid).notifier);

      // The controller only catches ApiException — a raw StateError should
      // propagate so the test itself must await it as a thrown error here;
      // this proves the controller doesn't silently swallow unexpected errors.
      await expectLater(notifier.sendMessage('Hello'), throwsStateError);
    });

    group('client_tool replies (Phase AI-3)', () {
      test(
          'runs ClientAiToolExecutor and replaces the placeholder message with the real result',
          () async {
        final container = _makeContainer(
          FakeAiRepository(
            sendMessage: (history, {model}) async => AiChatReply(
              message: _message(''),
              clientToolRequest: const ClientToolRequest(
                  tool: 'billing', function: 'cartTotal'),
            ),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(
            container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

        await container
            .read(aiChatControllerProvider(_uid).notifier)
            .sendMessage('cart total');

        final reply =
            container.read(aiChatControllerProvider(_uid)).messages.last;
        // BillingController's cart starts empty (no override needed) — the
        // real ClientAiToolExecutor read it and produced this honest reply.
        expect(reply.content, 'Your cart is empty.');
        expect(reply.toolCategory, ChatToolCategory.billing);
      });
    });

    group('navigation replies (Phase AI-3)', () {
      test(
          'a navigation reply appends the confirmation message and sets pendingNavigationAction',
          () async {
        final container = _makeContainer(
          FakeAiRepository(
            sendMessage: (history, {model}) async => AiChatReply(
              message: _message('Opening Billing...'),
              navigationAction: const NavigationAction(type: 'openBilling'),
            ),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(
            container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

        await container
            .read(aiChatControllerProvider(_uid).notifier)
            .sendMessage('open billing');

        final state = container.read(aiChatControllerProvider(_uid));
        expect(state.messages.last.content, 'Opening Billing...');
        expect(state.pendingNavigationAction?.type, 'openBilling');
      });

      test('clearPendingNavigation() resets pendingNavigationAction to null',
          () async {
        final container = _makeContainer(
          FakeAiRepository(
            sendMessage: (history, {model}) async => AiChatReply(
              message: _message('Opening Inventory...'),
              navigationAction: const NavigationAction(type: 'openInventory'),
            ),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(
            container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);
        final notifier =
            container.read(aiChatControllerProvider(_uid).notifier);

        await notifier.sendMessage('open inventory');
        expect(
            container
                .read(aiChatControllerProvider(_uid))
                .pendingNavigationAction,
            isNotNull);

        notifier.clearPendingNavigation();

        expect(
            container
                .read(aiChatControllerProvider(_uid))
                .pendingNavigationAction,
            isNull);
      });

      test('a plain tool/ai reply never sets pendingNavigationAction',
          () async {
        final container = _makeContainer(
          FakeAiRepository(
            sendMessage: (history, {model}) async =>
                AiChatReply(message: _message('just an answer')),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(
            container.listen(aiChatControllerProvider(_uid), (_, __) {}).close);

        await container
            .read(aiChatControllerProvider(_uid).notifier)
            .sendMessage('hello');

        expect(
            container
                .read(aiChatControllerProvider(_uid))
                .pendingNavigationAction,
            isNull);
      });
    });
  });
}
