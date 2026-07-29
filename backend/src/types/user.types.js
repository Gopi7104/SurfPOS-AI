'use strict';

// JSDoc-only type definitions — see src/types/README.md. No runtime exports.

/**
 * The identity `auth.middleware.js` attaches to `req.user` after verifying a Firebase ID token.
 * `merchantId`/`role`/`storeIds` are deliberately never attached here — resolving them would mean
 * a `users/{uid}` read on every authenticated request. `GET /auth/me`
 * (`modules/auth/auth.service.js#getCurrentUser`) is the one place that profile is resolved, as
 * its own response, not by mutating `req.user` (see docs/03_DATABASE_DESIGN.md § 4.10 for the full
 * `users/{uid}` shape); they're documented here so call sites already know the eventual full shape
 * if a future authorization module decides to attach them.
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
