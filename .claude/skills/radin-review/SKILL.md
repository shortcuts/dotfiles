---
name: radin-review
description: |
  Run a thermo-nuclear code quality review over a scope (commit, PR, directory,
  or a range like "since yesterday") and log each finding as a backlog entry
  instead of printing to terminal. Use for /radin-review, "review and log to
  backlog", "audit this commit/PR/directory and file backlog entries", "turn
  this review into a backlog".
---
# Review to Backlog

Run `/thermo-nuclear` code quality review against caller-specified scope, persist every finding as structured backlog entry instead of printing to terminal. Turns one-off strict review into durable backlog `radin-execute` (or human) can work through later.

## Step 1: Resolve scope argument

User passes one argument, can be any of:

- **Commit hash** (e.g. `a1b2c3d`) — review that single commit's changes:
  `git show <hash>` / `git diff <hash>^..<hash>`.
- **PR reference** (e.g. `#123`, `123`, or GitHub PR URL) — resolve via
  `gh pr diff <number>` (add `--repo <owner>/<repo>` if URL points elsewhere than
  current repo's remote).
- **Directory path** — review current state of everything under that path (not diff —
  read files as they stand today).
- **Natural-language range** (e.g. `"last commits since yesterday"`,
  `"commits since Monday"`, `"the last 5 commits"`) — translate into concrete
  `git log` / `git diff` invocation, e.g. `git log --since=yesterday --oneline` then
  `git diff <oldest-of-those>^..HEAD`.
- **No argument** — default to working branch's diff against its base
  (`git merge-base main HEAD` or `master`, whichever exists), same default `/code-review`
  would use.

Argument ambiguous (e.g. could be commit hash or directory
name, or PR number doesn't resolve via `gh`) — ask user. Don't guess.

State resolved scope back in one line before proceeding, e.g.:
`Scope: commit a1b2c3d` or `Scope: PR #123 (algolia/foo)` or `Scope: directory src/auth/`.

## Step 2: Record backlog baseline

Backlog writes go through shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh` — resolves per-project
backlog paths itself; never hand-edit index or task file. Record
baseline now so you can report net-new findings at end:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" show 2>/dev/null | wc -l
```

## Step 3: Run reviews

If `code-review-graph` installed and wired for this repo (`command -v
code-review-graph` succeeds, and its MCP tools available), use
`detect_changes` + `get_review_context` against resolved scope first —
risk-scored, token-efficient source context beats reading raw diffs/files
cold. Not installed or not wired here — fall back to
`git show`/`git diff`/reading files directly, same as Step 1's scope
resolution.

Invoke `/thermo-nuclear` against resolved scope. Apply full standards:
ambitious code-judo restructuring, 1k-line file smell, spaghetti branching,
boundary/type cleanliness, canonical-layer leaks, orchestration atomicity —
see that skill for complete rubric. Don't water down for this skill.

Then invoke ponytail complexity pass over same scope: `/ponytail-review`
for commit/PR/range (diff scope), `/ponytail-audit` for directory
(whole-tree scope). Hunts different axis than thermo-nuclear —
over-engineering, dead flexibility, reinvented stdlib/native code — and
complements it rather than duplicating it.

## Step 4: Log every finding to backlog

For each finding review surfaces, classify it:

- **fix** — finding is actual bug: incorrect behavior, not just
  structure.
- **refactor** — finding is structural: spaghetti branching, canonical-
  layer leak, 1k-line-file smell, orchestration atomicity, or any other
  restructuring thermo-nuclear calls for that doesn't change behavior. Every
  ponytail-pass finding (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`) is
  structural by definition — classify these as refactor too.

Then append each via CLI (handles file creation and section
ordering):

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed — commit hash / PR / directory / range from Step 1>
**Location:** <file path(s) and function/line if applicable>
**Finding:**
<the structural problem, stated the way the thermo-nuclear skill states it — direct,
specific, no hedging>
**Preferred remedy:**
<the concrete restructuring suggested — extract helper, delete wrapper, split file,
reframe state model, etc.>
EOF
```

Description under title should be as exhaustive as finding
warrants — `Scope`/`Location`/`Finding`/`Preferred remedy` are that
description's internal structure, not separate schema.

Log every finding that clears either pass's bar — thermo-nuclear's or
ponytail's. Don't filter down to only scariest one, but also don't pad
file with cosmetic nits neither skill would have raised itself. One
entry per finding, appended in order reviews produced them.

## Step 5: Report back

Tell user:

- Resolved scope reviewed.
- How many findings logged (net-new lines/entries vs. Step 2 baseline).
- Path to backlog index written to.
- Zero findings: say clearly review passed both thermo-nuclear's
  and ponytail's approval bar with no logged issues. Don't write empty
  entry just to prove skill ran.