import { describe, it, expect } from 'vitest';
import { withTimeout } from '../../../src/integrations/surfboard/middleware/timeout.middleware.js';

describe('withTimeout', () => {
  it('resolves normally when the operation finishes before the timeout', async () => {
    const result = await withTimeout(async () => 'done', 100);

    expect(result).toBe('done');
  });

  it('aborts the signal and rejects when the operation exceeds the timeout', async () => {
    const executeFn = (signal) =>
      new Promise((_resolve, reject) => {
        signal.addEventListener('abort', () => {
          const error = new Error('aborted');
          error.name = 'AbortError';
          reject(error);
        });
      });

    await expect(withTimeout(executeFn, 20)).rejects.toMatchObject({ name: 'AbortError' });
  });

  it('passes an AbortSignal to the executor', async () => {
    let receivedSignal;
    await withTimeout(async (signal) => {
      receivedSignal = signal;
      return 'ok';
    }, 100);

    expect(receivedSignal).toBeInstanceOf(AbortSignal);
    expect(receivedSignal.aborted).toBe(false);
  });
});
