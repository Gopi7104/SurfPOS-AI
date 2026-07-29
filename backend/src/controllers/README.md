# controllers/

Request-in/response-out only: parse the request, call one (or a small composition of) service methods, format the response using the standard envelope from [docs/04_API_DOCUMENTATION.md § 1](../../../docs/04_API_DOCUMENTATION.md#1-conventions). Target under ~40 lines per controller function (see [docs/07_CODING_RULES.md § 4](../../../docs/07_CODING_RULES.md#4-component-size-limits)) — anything longer belongs in a service.
