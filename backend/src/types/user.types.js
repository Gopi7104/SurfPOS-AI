'use strict';

// JSDoc-only type definitions — see src/types/README.md. No runtime exports.

/**
 * The identity `auth.middleware.js` attaches to `req.user` after verifying a Firebase ID token.
 * `merchantId`/`role`/`storeIds` are not populated yet — no module reads `users/{uid}` to resolve
 * them (see docs/03_DATABASE_DESIGN.md § 4.1); they're documented here so call sites already know
 * the eventual full shape.
 *
 * @typedef {Object} AuthenticatedUser
 * @property {string} uid
 * @property {string|null} email
 * @property {string|null} phoneNumber
 * @property {string} [merchantId]
 * @property {'owner'|'staff'} [role]
 * @property {Record<string, true>} [storeIds]
 */

module.exports = {};
