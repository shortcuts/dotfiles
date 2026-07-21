---
name: radin-stats
description: |
  Show stats/gain output from every companion tool that ships one, side by
  side. Use for /radin-stats, "show me all my stats", "aggregate my tool
  gains", "what savings am I getting from these tools".
---
# Stats Roundup

Surface each installed companion tool's own stats/gain command, back to back.
No merged total: the numbers below use incompatible units (real per-session
tokens, static benchmark medians, a counted per-repo ledger) — summing them
would misrepresent all three, so display each as-is instead.

## Step 1: Invoke each available source

Run whichever of these are installed (`command -v` / skill lookup — skip
silently if missing, don't error):

- **`/caveman-stats`** — real per-session token usage and savings, read from
  the session log itself.
- **`/ponytail-gain`** — ponytail's published benchmark scoreboard (medians
  across 5 tasks, 3 models). Not this session, not this repo.
- **`/ponytail-debt`** — ponytail's real per-repo ledger of deferred
  shortcuts, if this repo has one.
- **`rtk gain`** — rtk's real token-savings ledger (`command -v rtk`; use
  `-p` to scope to the current project).

Any other installed tool with its own `stats`/`gain` command belongs here
too — add it to this list, don't build a separate skill.

If a source (e.g. `caveman-stats`) finds nothing to report, treat that as a
normal empty result — one quick check, then move on. Don't keep searching
for entries that aren't there. This is informative only, not exact/precise
required.

## Step 2: Display, don't merge

Print each tool's output under its own heading, in the order above. Label
which are real-measured (caveman-stats, ponytail-debt, rtk gain) vs.
fixed-benchmark (ponytail-gain) so the user doesn't mistake one for the
other. Do not add a combined total row.
