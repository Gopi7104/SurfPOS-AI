# src/integrations/

Low-level, reusable HTTP client wrappers for third-party APIs — the raw request/auth plumbing
only, never business logic. This is distinct from `src/modules/<provider>/`, which will hold the
orchestration/business-rule layer that _uses_ these clients (e.g. "confirm an invoice scan and
create an order" belongs in `src/modules/ai/` and `src/modules/inventory/`, not here).

See `docs/17_FOLDER_STRUCTURE.md` § "integrations/ vs modules/" and
`docs/08_ARCHITECTURE_DECISIONS.md § ADR-013` for why this split exists.

## surfboard/

The Surfboard SDK (Phase 2, see `docs/22_DEVELOPMENT_ROADMAP.md`) — real HTTP client
infrastructure (`client/`, `middleware/`, `models/`, `mappers/`, `utils/`, `errors/`) that every
domain client (`auth.client.js`, `merchant.client.js`, `payment.client.js`, `store.client.js`,
`device.client.js`, `branding.client.js`) extends. **No domain methods are implemented yet** — each
domain client only gets a fully working `request()` (auth headers, retry, timeout, logging, error
mapping) for free from `client/surfboardClient.base.js`; actual API calls (`createMerchant()`, etc.)
are added phase-by-phase per `docs/22_DEVELOPMENT_ROADMAP.md`. The exact Surfboard wire-level API
surface (base URL, auth scheme, endpoint paths) is still unconfirmed against official docs
(`docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`) — see the accuracy note atop
`docs/15_SURFBOARD_INTEGRATION.md`.
