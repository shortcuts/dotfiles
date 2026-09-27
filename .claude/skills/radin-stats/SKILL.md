---
name: radin-stats
description: |
  Show the stats/gain output of every companion tool that ships one, side by
  side.
disable-model-invocation: true
---
# Stats Roundup

Print each installed tool's own stats or gain command, back to back. Do not
compute a merged total: the numbers use incompatible units -- real
per-session tokens, static benchmark medians, and a counted per-repo ledger.
A sum would misrepresent all three. Display each output as-is.

## Run every source

Run all five. Do not probe first: a source that is not installed fails
visibly, and that failure is the skip -- never an error, never worth retrying.

- **`/caveman:caveman-stats`** -- measured: real per-session token usage and
  savings, read from the session log itself.
- **`/ponytail:ponytail-gain`** -- benchmark: ponytail's published scoreboard
  (medians across 5 tasks, 3 models). Not this session, and not this repo.
- **`/ponytail:ponytail-debt`** -- measured: ponytail's per-repo ledger of
  deferred shortcuts, if the repo has one.
- **`rtk gain`** -- measured: rtk's token-savings ledger (pass `-p` to scope it
  to the current project).
- **`headroom savings`** -- measured: headroom's compression ledger. "No
  savings recorded yet" is a normal empty result: nothing has been routed
  through its proxy or MCP tool.
