import { describe, it, expect } from 'vitest';
import { generateRequestId } from '../../../src/integrations/surfboard/utils/requestId.js';

describe('generateRequestId', () => {
  it('returns an sb_req_-prefixed UUID', () => {
    expect(generateRequestId()).toMatch(/^sb_req_[0-9a-f-]{36}$/);
  });

  it('returns a unique value on every call', () => {
    expect(generateRequestId()).not.toBe(generateRequestId());
  });
});
