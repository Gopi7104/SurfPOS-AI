# services/

Shared/cross-cutting business logic used by more than one module (e.g. shared formatting/calculation helpers). Domain-specific services (sales, inventory, payments, AI, etc.) live under `src/modules/<name>/` instead — see [modules/README.md](../modules/README.md).

Rule: a controller never talks to Firebase directly, only through a service (see [docs/07_CODING_RULES.md § 3](../../../docs/07_CODING_RULES.md#3-folder-conventions)).
