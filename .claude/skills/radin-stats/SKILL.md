---
name: radin-stats
description: |
  Show stats/gain output from every companion tool that ships one, side by
  side. Use for /radin-stats, "show me all my stats", "aggregate my tool
  gains", "what savings am I getting from these tools".
---
# Stats Roundup

Print each installed tool's own stats or gain command, back to back. Do not
compute a merged total: the numbers use incompatible units -- real
per-session tokens, static benchmark medians, and a counted per-repo ledger.
A sum would misrepresent all three. Display each output as-is.

## Step 1: Invoke each available source

Run whichever sources are installed, checking with `command -v` or a skill
lookup. Skip a missing source without printing anything, and never treat it
as an error.

- **`/caveman-stats`** -- real per-session token usage and savings, read from
  the session log itself.
- **`/ponytail-gain`** -- ponytail's published benchmark scoreboard (medians
  across 5 tasks, 3 models). Not this session, and not this repo.
- **`/ponytail-debt`** -- ponytail's real per-repo ledger of deferred
  shortcuts, if the repo has one.
- **`rtk gain`** -- rtk's real token-savings ledger (`command -v rtk`; pass
  `-p` to scope it to the current project).

Any other installed tool with its own `stats` or `gain` command belongs in
this list too. Add it here rather than building a separate skill.

If a source finds nothing to report, treat that as a normal empty result:
one quick check, then move on. Do not keep searching for entries that are
not there. This output is informative only, so it does not need to be exact.

## Step 2: Display, don't merge

Print each tool's output under its own heading, in the order above. Label
which numbers are really measured (caveman-stats, ponytail-debt, rtk gain)
and which come from a fixed benchmark (ponytail-gain), so the user does not
mistake one for the other. Print no combined total row.
