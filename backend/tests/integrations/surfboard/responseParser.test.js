import { describe, it, expect } from 'vitest';
import { parseResponse } from '../../../src/integrations/surfboard/utils/responseParser.js';

describe('parseResponse', () => {
  it('parses a JSON body', async () => {
    const response = new Response(JSON.stringify({ id: '1' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

    const result = await parseResponse(response);

    expect(result).toEqual({
      status: 200,
      headers: { 'content-type': 'application/json' },
      data: { id: '1' },
      ok: true,
    });
  });

  it('returns null data for an empty body', async () => {
    const response = new Response(null, { status: 204 });

    const result = await parseResponse(response);

    expect(result.data).toBeNull();
    expect(result.ok).toBe(true);
  });

  it('falls back to raw text when the body is not valid JSON', async () => {
    const response = new Response('not json', { status: 200 });

    const result = await parseResponse(response);

    expect(result.data).toBe('not json');
  });

  it('reports ok:false for a non-2xx status', async () => {
    const response = new Response(JSON.stringify({ message: 'nope' }), { status: 404 });

    const result = await parseResponse(response);

    expect(result.ok).toBe(false);
    expect(result.status).toBe(404);
  });
});
