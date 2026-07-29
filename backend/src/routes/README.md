# routes/

Express route definitions only — maps HTTP method + path to a controller function. No business logic, no direct Firebase calls (see [docs/07_CODING_RULES.md § 3](../../../docs/07_CODING_RULES.md#3-folder-conventions)).

One file per resource (e.g. `products.routes.js`, `sales.routes.js`), matching the endpoints documented in [docs/04_API_DOCUMENTATION.md](../../../docs/04_API_DOCUMENTATION.md).
