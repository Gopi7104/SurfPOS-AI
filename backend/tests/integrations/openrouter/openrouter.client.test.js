import { describe, it, expect, vi } from 'vitest';
import { createOpenRouterClient } from '../../../src/integrations/openrouter/openrouter.client.js';

function createClient({ fetchImpl, config } = {}) {
  return createOpenRouterClient({
    fetchImpl,
    logger: { debug: vi.fn(), warn: vi.fn(), error: vi.fn() },
    config: {
      apiKey: 'test-key',
      baseUrl: 'https://openrouter.example.test/api/v1',
      defaultModel: 'openai/gpt-5-mini',
      timeoutMs: 200,
      ...config,
    },
  });
}

describe('openrouter.client', () => {
  it('returns the parsed message content on a successful response', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          model: 'openai/gpt-5-mini',
          choices: [{ message: { role: 'assistant', content: 'Hello!' }, finish_reason: 'stop' }],
          usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const client = createClient({ fetchImpl });

    const result = await client.chatCompletion({ messages: [{ role: 'user', content: 'Hi' }] });

    expect(result).toEqual({
      content: 'Hello!',
      model: 'openai/gpt-5-mini',
      finishReason: 'stop',
      usage: { promptTokens: 10, completionTokens: 5, totalTokens: 15 },
    });
  });

  it('sends an Authorization header and the requested model', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify({ choices: [{ message: { content: 'ok' } }] }), { status: 200 }),
      );
    const client = createClient({ fetchImpl });

    await client.chatCompletion({
      model: 'anthropic/claude-4-sonnet',
      messages: [{ role: 'user', content: 'Hi' }],
    });

    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://openrouter.example.test/api/v1/chat/completions');
    expect(init.headers.Authorization).toBe('Bearer test-key');
    expect(JSON.parse(init.body).model).toBe('anthropic/claude-4-sonnet');
  });

  it('throws AI_NOT_CONFIGURED when no API key is set, without calling fetch', async () => {
    const fetchImpl = vi.fn();
    const client = createClient({ fetchImpl, config: { apiKey: undefined } });

    await expect(
      client.chatCompletion({ messages: [{ role: 'user', content: 'Hi' }] }),
    ).rejects.toMatchObject({ code: 'AI_PROCESSING_ERROR' });
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it('maps a 429 response to a RATE_LIMITED error', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ error: { message: 'slow down' } }), { status: 429 }));
    const client = createClient({ fetchImpl });

    await expect(
      client.chatCompletion({ messages: [{ role: 'user', content: 'Hi' }] }),
    ).rejects.toMatchObject({ code: 'RATE_LIMITED', statusCode: 429 });
  });

  it('maps a 401 response to a generic not-configured error without leaking the upstream message', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ error: { message: 'Invalid API key sk-secret-123' } }), {
        status: 401,
      }),
    );
    const client = createClient({ fetchImpl });

    await expect(
      client.chatCompletion({ messages: [{ role: 'user', content: 'Hi' }] }),
    ).rejects.toMatchObject({ message: expect.not.stringContaining('sk-secret-123') });
  });

  it('maps an aborted (timeout) request to AI_TIMEOUT', async () => {
    const fetchImpl = vi.fn().mockImplementation(() => {
      const error = new Error('The operation was aborted');
      error.name = 'AbortError';
      return Promise.reject(error);
    });
    const client = createClient({ fetchImpl });

    await expect(
      client.chatCompletion({ messages: [{ role: 'user', content: 'Hi' }] }),
    ).rejects.toMatchObject({ code: 'AI_PROCESSING_ERROR' });
  });
});
