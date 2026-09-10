# AGENTS.md — scripts/

Personal scripts. One directory per scope, loose files for one-offs.

```
scripts/
├── algolia/               # Algolia index maintenance, see algolia/README.md
├── inv.sh                 # poke-idle.fr raffle bot
└── tmux-session-finder    # fzf project picker that attaches a tmux session
```

## algolia/

Node scripts (`.mjs`, ESM) that use the `algoliasearch` v5 client. Run
`npm install` in `algolia/` once. `node_modules/` is git-ignored.

Never hardcode credentials. Every script reads `ALGOLIA_APP_ID` and
`ALGOLIA_API_KEY` through `client()` in `algolia/lib.mjs`, which exits 1 when
either is missing. Keep new scripts on that helper.

`algolia/README.md` holds the user-facing usage. Update it with every change.

### Files

- `lib.mjs` — shared helpers: `flags()` (parses `--key=value` into `opts` and
  positionals into `rest`), `client()`, `clusterClient()`, `retry()`.
- `delete-indices-on-app.mjs` — selects indices by name, `--match=regex`, or
  `--stale-days=N`, then deletes them. Filters combine with AND.
- `upload-records-from-file.mjs` — streams a record file into an index.
- `check-index-on-clusters.mjs` — compares one index across cluster machines.

### Rules that the code depends on

- Deletion is dry run by default. `--yes` performs it. Keep that default when
  you add a destructive script.
- `clusterClient(cluster)` points the client at `<cluster>.algolia.net`. That
  bypasses the load-balanced DSN host, so per-cluster replication lag becomes
  visible. Do not swap it back to the default hosts.
- Cluster hosts do not return `numberOfPendingTasks`. `check-index-on-clusters`
  samples the stats twice, `--gap` milliseconds apart, and calls the index
  "indexing" when `updatedAt` or `entries` moved, or when the last write is
  under 60s old.
- `upload-records-from-file` parses one JSON record per line. NDJSON works. A
  pretty-printed JSON array works while each record stays on its own line. A
  file that wraps a record over several lines needs a streaming JSON parser.
- `retry()` retries 5 times with exponential backoff. Algolia rate-limits large
  uploads, so keep writes behind it.

### Known limits

- `listIndices()` returns the first page only. Add pagination above 100
  indices.
- Algolia refuses to delete a replica that is still attached to its primary.
  Detach the replica first.

## inv.sh

`inv.sh` calls the poke-idle.fr API. It uses a session cookie and a few
per-session tokens. These expire. The site returns an auth or version error
when they do. Fix the script from a fresh browser cURL command.

The script loops `count` raffles per banner (8 banners), backs off on
`retryAfter`, and records new shiny `speciesId`s in `.seen_shinies` because the
response carries no new-or-duplicate flag.

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

## tmux-session-finder

`fzf` over `~/Documents/*`, `~/.config`, `~/Downloads`, and the Obsidian vault.
It then attaches or creates a tmux session for the chosen directory. It matches
an existing session on `session_path`, not on name, because sessions get
renamed on the fly. Add new roots to the `printf` list inside the script.
