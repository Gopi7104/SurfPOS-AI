'use strict';

// Shared validation patterns — reused by validators/* (docs/07_CODING_RULES.md § 8: one place
// per piece of reusable logic, never copy-pasted).

module.exports = Object.freeze({
  // E.164 international phone format — see docs/04_API_DOCUMENTATION.md § 2 (POST /auth/register).
  E164_PHONE: /^\+[1-9]\d{7,14}$/,
  // Firebase Realtime Database push() key shape.
  FIREBASE_PUSH_ID: /^[A-Za-z0-9_-]{20}$/,
});
