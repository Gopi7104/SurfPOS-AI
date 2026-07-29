# modules/surfboard/

The Surfboard **business/orchestration layer** — webhook handling, payment reconciliation with
`payments`/`sales`, merchant-onboarding orchestration during registration. See
docs/15_SURFBOARD_INTEGRATION.md.

Distinct from [`src/integrations/surfboard/`](../../integrations/surfboard/README.md), which holds
the raw, reusable HTTP client wrappers this module will call — see
[docs/08_ARCHITECTURE_DECISIONS.md § ADR-013](../../../../docs/08_ARCHITECTURE_DECISIONS.md#adr-013--srcintegrations-vs-srcmodules-split).

Not yet implemented — this is a documentation-only scaffold (see [docs/13_CLAUDE_CONTEXT.md](../../../../docs/13_CLAUDE_CONTEXT.md)).
