'use strict';

// JSDoc-only type definitions — see backend/src/types/README.md for the pattern this follows.
// No runtime exports; reference via `@param {import('.../models/requestOptions').SurfboardRequestOptions}`.

/**
 * @typedef {Object} SurfboardRequestOptions
 * @property {'GET'|'POST'|'PATCH'|'PUT'|'DELETE'} method
 * @property {string} path
 * @property {Record<string, string|number|boolean|undefined|null>} [query]
 * @property {*} [body]
 * @property {Record<string, string>} [headers]
 */

module.exports = {};
