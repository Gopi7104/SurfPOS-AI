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
        source: 'ai',
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

  describe('sendChatMessage — tool routing (Phase AI-2)', () => {
    function createFakeToolRegistry(overrides = {}) {
      return {
        executeTool: vi.fn().mockResolvedValue({ available: true, message: 'Found 2 products.' }),
        ...overrides,
      };
    }

    it('runs the matched tool directly and never calls OpenRouter', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const toolRegistry = createFakeToolRegistry();
      const detectIntent = vi
        .fn()
        .mockReturnValue({ tool: 'inventory', function: 'search', params: { query: 'wax' } });
      const service = createAiService({ openRouterClient, toolRegistry, detectIntent });

      const result = await service.sendChatMessage([{ role: 'user', content: 'show products wax' }], {
        uid: 'uid-1',
      });

      expect(detectIntent).toHaveBeenCalledWith('show products wax');
      expect(toolRegistry.executeTool).toHaveBeenCalledWith(
        { tool: 'inventory', function: 'search', params: { query: 'wax' } },
        'uid-1',
      );
      expect(openRouterClient.chatCompletion).not.toHaveBeenCalled();
      expect(result).toEqual({
        message: { role: 'assistant', content: 'Found 2 products.' },
        model: null,
        finishReason: 'tool',
        usage: null,
        source: 'tool',
        tool: { name: 'inventory', function: 'search' },
      });
    });

    it('falls through to OpenRouter when no intent matches, even with a uid', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const toolRegistry = createFakeToolRegistry();
      const detectIntent = vi.fn().mockReturnValue(null);
      const service = createAiService({ openRouterClient, toolRegistry, detectIntent });

      const result = await service.sendChatMessage(
        [{ role: 'user', content: 'How can I grow my business?' }],
        { uid: 'uid-1' },
      );

      expect(toolRegistry.executeTool).not.toHaveBeenCalled();
      expect(openRouterClient.chatCompletion).toHaveBeenCalled();
      expect(result.source).toBe('ai');
    });

    it('never runs intent detection when no uid is provided', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const detectIntent = vi.fn().mockReturnValue({ tool: 'inventory', function: 'search', params: {} });
      const service = createAiService({ openRouterClient, detectIntent });

      const result = await service.sendChatMessage([{ role: 'user', content: 'show products' }]);

      expect(detectIntent).not.toHaveBeenCalled();
      expect(result.source).toBe('ai');
    });

    it('returns a friendly message instead of throwing when the matched tool fails', async () => {
      const toolRegistry = createFakeToolRegistry({
        executeTool: vi.fn().mockRejectedValue(new Error('boom')),
      });
      const detectIntent = vi.fn().mockReturnValue({ tool: 'inventory', function: 'search', params: {} });
      const service = createAiService({
        openRouterClient: createFakeOpenRouterClient(),
        toolRegistry,
        detectIntent,
        logger: { error: vi.fn(), info: vi.fn() },
      });

      const result = await service.sendChatMessage([{ role: 'user', content: 'show products' }], {
        uid: 'uid-1',
      });

      expect(result.source).toBe('tool');
      expect(result.message.content).toMatch(/problem looking that up/i);
    });
  });

  describe('sendChatMessage — navigation and client-executed tools (Phase AI-3)', () => {
    it('returns a navigation reply with a confirmation message, never calling OpenRouter or a tool', async () => {
      const openRouterClient = createFakeOpenRouterClient();
      const toolRegistry = { executeTool: vi.fn() };
      const service = createAiService({ openRouterClient, toolRegistry });

      const result = await service.sendChatMessage([{ role: 'user', content: 'open billing' }], {
        uid: 'uid-1',
      });

      expect(openRouterClient.chatCompletion).not.toHaveBeenCalled();
      expect(toolRegistry.executeTool).not.toHaveBeenCalled();
      expect(result).toEqual({
        message: { role: 'assistant', content: 'Opening Billing...' },
        model: null,
        finishReason: 'navigation',
        usage: null,
        source: 'navigation',
        action: { type: 'openBilling', params: {} },
      });
    });

    it('carries search params through the navigation action', async () => {
      const service = createAiService({ openRouterClient: createFakeOpenRouterClient() });

      const result = await service.sendChatMessage([{ role: 'user', content: 'search Coca Cola' }], {
        uid: 'uid-1',
      });

      expect(result.source).toBe('navigation');
      expect(result.action).toEqual({ type: 'searchInventory', params: { query: 'Coca Cola' } });
      expect(result.message.content).toContain('Coca Cola');
    });

    it.each(['billing', 'dashboard', 'reports', 'customer'])(
      'routes a %s question to source: client_tool without calling the backend registry or OpenRouter',
      async (tool) => {
        const messageByTool = {
          billing: 'cart total',
          dashboard: 'revenue today',
          reports: 'today sales',
          customer: 'customer count',
        };
        const openRouterClient = createFakeOpenRouterClient();
        const toolRegistry = { executeTool: vi.fn() };
        const service = createAiService({ openRouterClient, toolRegistry });

        const result = await service.sendChatMessage([{ role: 'user', content: messageByTool[tool] }], {
          uid: 'uid-1',
        });

        expect(openRouterClient.chatCompletion).not.toHaveBeenCalled();
        expect(toolRegistry.executeTool).not.toHaveBeenCalled();
        expect(result.source).toBe('client_tool');
        expect(result.tool.name).toBe(tool);
        expect(result.message.content).toBe('');
      },
    );
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
