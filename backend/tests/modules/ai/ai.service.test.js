import { describe, it, expect, vi } from 'vitest';
import { createAiService } from '../../../src/modules/ai/ai.service.js';
import { SURF_AI_SYSTEM_PROMPT } from '../../../src/modules/ai/prompts/systemPrompt.js';
import { ACTIVE_MODEL } from '../../../src/modules/ai/models.js';

function createFakeOpenRouterClient(overrides = {}) {
  return {
    chatCompletion: vi.fn().mockResolvedValue({
      content: 'Here is your answer.',
      model: ACTIVE_MODEL,
      finishReason: 'stop',
      usage: { promptTokens: 20, completionTokens: 8, totalTokens: 28 },
    }),
    ...overrides,
  };
}

describe('ai.service', () => {
  describe('sendChatMessage', () => {
    it('prepends the SurfAI system prompt to the conversation history', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const service = createAiService({ openRouterClient });

      await service.sendChatMessage([{ role: 'user', content: 'What sold the most today?' }]);

      expect(openRouterClient.chatCompletion).toHaveBeenCalledWith({
        model: ACTIVE_MODEL,
        messages: [
          { role: 'system', content: SURF_AI_SYSTEM_PROMPT },
          { role: 'user', content: 'What sold the most today?' },
        ],
      });
    });

    it('returns the assistant reply, model, and usage from the client', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const service = createAiService({ openRouterClient });

      const result = await service.sendChatMessage([{ role: 'user', content: 'Hi' }]);

      expect(result).toEqual({
        message: { role: 'assistant', content: 'Here is your answer.' },
        model: ACTIVE_MODEL,
        finishReason: 'stop',
        usage: { promptTokens: 20, completionTokens: 8, totalTokens: 28 },
      });
    });

    it('uses an explicitly requested model over the default', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const service = createAiService({ openRouterClient });

      await service.sendChatMessage([{ role: 'user', content: 'Hi' }], { model: 'deepseek/deepseek-chat' });

      expect(openRouterClient.chatCompletion).toHaveBeenCalledWith(
        expect.objectContaining({ model: 'deepseek/deepseek-chat' }),
      );
    });

    it('throws a ValidationError when messages is empty', async () => {
      const service = createAiService({ openRouterClient: createFakeOpenRouterClient() });

      await expect(service.sendChatMessage([])).rejects.toMatchObject({ code: 'VALIDATION_ERROR' });
    });
  });

  describe('getModelInfo', () => {
    it('returns the active model and the full available-models catalog', () => {
      const service = createAiService({ openRouterClient: createFakeOpenRouterClient() });

      const info = service.getModelInfo();

      expect(info.activeModel).toBe(ACTIVE_MODEL);
      expect(info.availableModels.map((m) => m.id)).toContain('openai/gpt-5-mini');
    });

    it('reports configured: false when no OPENROUTER_API_KEY is set', () => {
      const service = createAiService({
        openRouterClient: createFakeOpenRouterClient(),
        config: { openRouter: { apiKey: undefined } },
      });

      expect(service.getModelInfo().configured).toBe(false);
    });

    it('reports configured: true when an OPENROUTER_API_KEY is set', () => {
      const service = createAiService({
        openRouterClient: createFakeOpenRouterClient(),
        config: { openRouter: { apiKey: 'sk-test' } },
      });

      expect(service.getModelInfo().configured).toBe(true);
    });
  });

  describe('testConnection', () => {
    it('reports connected: true with a latency on success', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const service = createAiService({ openRouterClient });

      const result = await service.testConnection();

      expect(result.connected).toBe(true);
      expect(result.model).toBe(ACTIVE_MODEL);
      expect(typeof result.latencyMs).toBe('number');
      expect(result.error).toBeNull();
    });

    it('reports connected: false with an error message instead of throwing, on failure', async () => {
      const openRouterClient = createFakeOpenRouterClient({
        chatCompletion: vi.fn().mockRejectedValue(new Error('upstream is down')),
      });
      const service = createAiService({ openRouterClient });

      const result = await service.testConnection();

      expect(result.connected).toBe(false);
      expect(result.latencyMs).toBeNull();
      expect(result.error).toBe('upstream is down');
    });
  });
});
