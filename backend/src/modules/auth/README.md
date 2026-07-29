# modules/auth/

Application-user identity — Firebase Auth + `users/{uid}` profile only (Roadmap Phase 3, tasks 3.1–3.2). See docs/05_FEATURES.md § 2 and docs/04_API_DOCUMENTATION.md § 2.

- `auth.service.js` — sign-up (`createUser` + `users/{uid}` profile write, default role `owner`), token verification (shared with `middleware/auth.middleware.js`), login (verify + fetch profile), `GET /auth/me` lookup, sign-out (refresh-token revocation).
- `users.repository.js` — the only place `users/{uid}` is read/written.

Never creates a Merchant/Store/Surfboard record and never calls the Surfboard SDK — that's Phase 4's `POST /auth/register` orchestration. Staff-invite logic (task 3.3) is not yet implemented.
