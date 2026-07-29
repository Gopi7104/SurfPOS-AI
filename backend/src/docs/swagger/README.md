# src/docs/swagger/

Reserved structure for a future OpenAPI/Swagger specification generated from (or kept in sync
with) `docs/04_API_DOCUMENTATION.md`, the canonical human-authored API reference. **No spec has
been generated yet** — this is folder scaffolding only.

Planned layout, populated as each route is actually built:

- `paths/` — one file per resource, each exporting its OpenAPI path-item objects.
- `components/` — reusable request/response schemas, security schemes, parameters.
- `schemas/` — JSON Schema / OpenAPI schema objects mirroring `docs/03_DATABASE_DESIGN.md` node
  shapes.

Whether this is authored by hand, generated via `swagger-jsdoc` from route annotations, or
generated from the `zod` validators in `src/validators/` is an open implementation choice to make
when this folder is actually populated — not decided yet.
