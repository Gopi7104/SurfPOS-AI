# src/types/

Shared type definitions used across the backend. The codebase is plain JavaScript, not
TypeScript, so these are **JSDoc `@typedef` declarations only** — no runtime exports, no compiler
step. Reference them from anywhere with an import-type JSDoc comment, e.g.:

```js
/** @param {import('../types/user.types').AuthenticatedUser} user */
function example(user) {}
```

Keep these in sync with the shape they document (`docs/03_DATABASE_DESIGN.md` for persisted
records, `docs/04_API_DOCUMENTATION.md` for request/response shapes) rather than letting them
drift into a second, undocumented source of truth.
