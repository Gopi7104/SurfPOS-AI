'use strict';

// Turns a SurfboardRequestOptions (see models/requestOptions.js) plus a base URL into the
// concrete { url, init } pair passed to fetch() — the only place a Surfboard URL gets assembled.

/**
 * @param {string} baseUrl
 * @param {string} path
 * @param {Record<string, string|number|boolean|undefined|null>} [query]
 */
function buildUrl(baseUrl, path, query) {
  const normalizedBase = baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`;
  const url = new URL(path.replace(/^\//, ''), normalizedBase);

  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined && value !== null) {
        url.searchParams.set(key, String(value));
      }
    }
  }

  return url;
}

/**
 * @param {{ baseUrl: string, method: string, path: string, query?: object, body?: *, headers?: object }} options
 * @returns {{ url: string, init: RequestInit }}
 */
function buildRequest({ baseUrl, method, path, query, body, headers = {} }) {
  const url = buildUrl(baseUrl, path, query);

  const init = {
    method,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...headers },
  };

  if (body !== undefined) {
    init.body = JSON.stringify(body);
  }

  return { url: url.toString(), init };
}

module.exports = { buildUrl, buildRequest };
