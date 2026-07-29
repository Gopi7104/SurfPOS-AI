import { describe, it, expect, vi } from 'vitest';
import { withRetry } from '../../../src/integrations/surfboard/middleware/retry.middleware.js';

describe('withRetry', () => {
  it('returns the result immediately when the first attempt succeeds', async () => {
    const attempt = vi.fn().mockResolvedValue({ status: 200 });

    const result = await withRetry(attempt, { maxRetries: 2, baseDelayMs: 1 });

    expect(result.status).toBe(200);
    expect(attempt).toHaveBeenCalledTimes(1);
  });

  it('retries on a retryable status code up to maxRetries', async () => {
    const attempt = vi
      .fn()
      .mockResolvedValueOnce({ status: 503 })
      .mockResolvedValueOnce({ status: 502 })
      .mockResolvedValueOnce({ status: 200 });

    const result = await withRetry(attempt, { maxRetries: 2, baseDelayMs: 1 });

    expect(result.status).toBe(200);
    expect(attempt).toHaveBeenCalledTimes(3);
  });

  it('gives up after maxRetries and returns the last retryable response', async () => {
    const attempt = vi.fn().mockResolvedValue({ status: 503 });

    const result = await withRetry(attempt, { maxRetries: 2, baseDelayMs: 1 });

    expect(result.status).toBe(503);
    expect(attempt).toHaveBeenCalledTimes(3);
  });

  it('does not retry a non-retryable status code', async () => {
    const attempt = vi.fn().mockResolvedValue({ status: 400 });

    const result = await withRetry(attempt, { maxRetries: 2, baseDelayMs: 1 });

    expect(result.status).toBe(400);
    expect(attempt).toHaveBeenCalledTimes(1);
  });

  it('retries a retryable thrown error and eventually rethrows it', async () => {
    const error = Object.assign(new Error('reset'), { code: 'ECONNRESET' });
    const attempt = vi.fn().mockRejectedValue(error);

    await expect(withRetry(attempt, { maxRetries: 1, baseDelayMs: 1 })).rejects.toBe(error);
    expect(attempt).toHaveBeenCalledTimes(2);
  });

  it('does not retry a non-retryable thrown error', async () => {
    const error = new Error('boom');
    const attempt = vi.fn().mockRejectedValue(error);

    await expect(withRetry(attempt, { maxRetries: 2, baseDelayMs: 1 })).rejects.toBe(error);
    expect(attempt).toHaveBeenCalledTimes(1);
  });

  it('invokes onRetry with attempt number and backoff before each retry', async () => {
    const attempt = vi.fn().mockResolvedValueOnce({ status: 503 }).mockResolvedValueOnce({ status: 200 });
    const onRetry = vi.fn();

    await withRetry(attempt, { maxRetries: 1, baseDelayMs: 5, onRetry });

    expect(onRetry).toHaveBeenCalledWith(expect.objectContaining({ attemptNumber: 1, backoffMs: 5 }));
  });
});
