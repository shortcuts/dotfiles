# CLAUDE.md

Payment reconciliation service. Non-obvious constraints:

- Money amounts are integer cents everywhere. The one exception is the legacy
  `/v1/invoices` response, which returns decimal strings — convert at the
  boundary in `src/legacy/adapter.ts`, nowhere else.
- `npm test` needs the dockerized Postgres up first (`make db-up`); without
  it, tests fail with a misleading auth error, not a connection error.
- The Stripe webhook handler must stay idempotent — Stripe retries for up to
  3 days and duplicate events have caused double payouts before.
- Generated files under `src/gen/` are overwritten by `make codegen`; edit
  the templates in `codegen/templates/` instead.
