---
name: radin-stats
description: |
  Show stats/gain output from every companion tool that ships one, side by
  side. Use for /radin-stats, "show me all my stats", "aggregate my tool
  gains", "what savings am I getting from these tools".
---
# Stats Roundup

Each installed tool print own stats/gain command, back to back. No merged total: numbers use incompatible units — real per-session tokens, static benchmark medians, counted per-repo ledger. Sum would misrepresent all three. Display each as-is.

## Step 1: Invoke each available source

Run whichever installed (`command -v` / skill lookup — skip silent if missing, don't error):

- **`/caveman-stats`** — real per-session token usage and savings, read from session log itself.
- **`/ponytail-gain`** — ponytail's published benchmark scoreboard (medians across 5 tasks, 3 models). Not this session, not this repo.
- **`/ponytail-debt`** — ponytail's real per-repo ledger of deferred shortcuts, if repo has one.
- **`rtk gain`** — rtk's real token-savings ledger (`command -v rtk`; use `-p` to scope to current project).

Other installed tool with own `stats`/`gain` command belongs here too — add to list, don't build separate skill.

If source (e.g. `caveman-stats`) finds nothing to report, treat as normal empty result: one quick check, move on. Don't keep searching for entries not there. Informative only — doesn't need exact.

## Step 2: Display, don't merge

Print each tool's output under own heading, in order above. Label which real-measured (caveman-stats, ponytail-debt, rtk gain) vs. fixed-benchmark (ponytail-gain) so user doesn't mistake one for other. No combined total row.
