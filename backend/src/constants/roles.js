'use strict';

// User roles — see docs/03_DATABASE_DESIGN.md § 4.10 (users/{uid}.role).
// Enforced at signup (default role: owner, see modules/auth/auth.service.js) — authorization
// (role-gated endpoints) is not yet implemented.

module.exports = Object.freeze({
  OWNER: 'owner',
  STAFF: 'staff',
});
