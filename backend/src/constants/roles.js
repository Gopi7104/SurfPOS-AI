'use strict';

// User roles — see docs/03_DATABASE_DESIGN.md § 4.1 (users/{uid}.role).
// Not yet enforced anywhere (no auth/authorization module exists yet) — defined ahead of that
// work so every future reference to a role string uses this instead of a literal.

module.exports = Object.freeze({
  OWNER: 'owner',
  STAFF: 'staff',
});
