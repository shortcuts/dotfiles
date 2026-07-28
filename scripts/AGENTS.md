# AGENTS.md — scripts/

## inv.sh

`inv.sh` calls the poke-idle.fr API. It uses a session cookie and a few
per-session tokens. These expire. The site returns an auth or version error
when they do. Fix the script from a fresh browser cURL command.

### How to update the script

1. Ask the user for a fresh cURL command, copied from the browser's network
   tab (right-click a request → Copy as cURL).
2. Copy every `Cookie:` value from that cURL into the `cookie` variable in
   `inv.sh`. The site now requires three cookies: `remember_web`,
   `adonis-session`, `kv39z1y2gb1c10y49ory5hms`. One cookie alone returns
   `Unauthorized access`.
3. Test `fetch_gold` (the `farm-sync` call) directly with `curl`, using the
   new cookie and the old body. If it returns
   `{"message":"Client outdated — reload required", ..., "serverBootId":"..."}`,
   the body's `sessionToken`, `adminVersion`, or `serverBootId` are stale.
4. Get fresh values for those three fields:
   - `serverBootId` — read it straight from the error response above.
   - `sessionToken` and `adminVersion` — copy from any other fresh request
     body in the same cURL dump (e.g. a `daycare` or `invocations` call).
5. Retry the `curl` test. A `"message":"Farm sync saved"` response confirms
   the fix. Then update `inv.sh` with the same values and rerun the script.

### Notes

- `sessionToken` and `serverBootId` go stale again after the next server
  deploy or session refresh. Repeat this process when the script starts
  failing.
- The `/api/invocations` call has no version fields in its body, only the
  cookie affects it.
