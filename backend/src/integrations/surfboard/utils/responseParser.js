'use strict';

// Normalizes a fetch Response into a plain SurfboardResponse (see models/response.js) — the only
// place `.json()`/`.text()` is called, so every caller works with one consistent shape regardless
// of whether Surfboard returned JSON, an empty body, or something else.

/**
 * @param {Response} response
 * @returns {Promise<import('../models/response').SurfboardResponse>}
 */
async function parseResponse(response) {
  const headers = Object.fromEntries(response.headers.entries());
  const text = await response.text();

  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  return { status: response.status, headers, data, ok: response.ok };
}

module.exports = { parseResponse };
