# PIL-442 client security controls

This change hardens the customer-list flow against disclosure through diagnostics
and exceptional conditions. It does not claim that a client-side change prevents
every OWASP Top 10 risk. Authorization, tenant isolation, query validation,
pagination limits, and throttling are enforced by the backend.

## Diagnostic privacy

The shared HTTP interceptor now records event category, an allowlisted HTTP
method, status code, and exception type only. It never logs URLs, header values,
query parameters, request bodies, response bodies, or raw error messages.
Redaction is omission rather than a list of secret field names: customer names,
search text, balances, bearer tokens, cookies, and future nested token fields
cannot accidentally bypass a name-based rule. The actual HTTP request and
response are not changed.

This is a shared-client change because the customer list uses the same network
pipeline as login and the rest of the app. It addresses information exposure
(OWASP A04:2025) while retaining non-sensitive diagnostic categories (A09:2025).
Do not add request or response contents back to logs, even for debug builds.

## Safe customer-list failures

`NasabahRepositoryImpl.getNasabah()` converts failures to fixed Indonesian
messages before presentation. Timeout, connectivity, authentication, access
denial, invalid filters, and HTTP 429 each have an actionable message. Other
HTTP errors, malformed responses, and unexpected exceptions use a generic
retry message. HTML responses, decoder source text, stack traces, and backend
diagnostics never become customer-list UI text (A10:2025).

Only this list operation changes error-message handling. Validation and field
errors for customer writes and other features retain their existing behavior.
Retry continues using the current status, query, order, and pagination rules.
An HTTP 429 message does not bypass or replace the backend's quota.

## Regression checks

- `test/core/client/network_service_privacy_test.dart` captures debug logs for
  successful, rejected, multipart, and malformed requests. It checks that
  credentials, customer data, URL values, and raw diagnostics are absent and
  that request/response data remain unchanged.
- `test/features/nasabah/data/repositories/nasabah_repository_security_test.dart`
  checks safe messages for exceptional responses and a real-stack 429/retry
  scenario that preserves search and status.

The existing customer-list ordering, reset, and pagination tests still apply.
The manual Burp checks should inspect actual HTTP traffic; redacted client logs
are not evidence of which credentials or data crossed the network.
