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

This review logs every finding as a backlog entry instead of printing it to the terminal. Run `/thermo-nuclear` against the caller-specified scope. Persist each finding as a structured backlog entry. This turns a one-off strict review into a durable backlog that `radin-execute` (or a human) works through later.

## Step 1: Resolve scope argument

The user passes one argument (or none). Resolve the mechanical cases via
the shared CLI — don't probe git/gh by hand:

```bash
bash "$HOME/.claude/.radin/lib/radin-scope.sh" [<arg>]
```

It settles a commit hash, a PR reference (`#123`, `123`, a GitHub PR URL),
a directory path, and the no-argument default (the working branch's diff
against its merge-base with main/master). Exit codes:

- **0** — resolved. It prints `type`/`scope`/`command` lines; run the
  printed command to get the scope's content.
- **1** — not a commit, PR, or directory. If the argument is a
  **natural-language range** (e.g. `"last commits since yesterday"`,
  `"the last 5 commits"`), that's yours to translate into a concrete
  `git log` / `git diff` invocation, e.g. `git log --since=yesterday
  --oneline` then `git diff <oldest-of-those>^..HEAD`. Otherwise the
  argument doesn't resolve — report it.
- **2** — genuinely ambiguous: the argument reads several valid ways
  (candidates on stderr, e.g. both a PR number and a directory):

- **Invoked interactively** (a live user is in this conversation): ask
  which one they meant. Don't guess.
- **Invoked non-interactively** (a sub-agent, e.g. `radin-execute` Phase 6's
  reviewer sub-agent): there's no one to ask. Stop and report the ambiguity
  — both readings and why neither resolved — instead of picking one. The
  caller either passes an unambiguous scope on retry or resolves it with the
  user itself.

State the resolved scope in one line before proceeding, e.g.:
`Scope: commit a1b2c3d` or `Scope: PR #123 (algolia/foo)` or `Scope: directory src/auth/`.

## Step 2: Record backlog baseline

Backlog writes go through the shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh`. The CLI resolves per-project
backlog paths itself. Never hand-edit the index or task file. Record the
baseline now so you can report net-new findings at the end:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" count
```

## Step 3: Run reviews

If `code-review-graph` is installed and wired for this repo (`command -v
code-review-graph` succeeds, and its MCP tools are available), use
`detect_changes` + `get_review_context` against the resolved scope first.
Risk-scored, token-efficient source context beats reading raw diffs or files
cold. If it is not installed or not wired here, fall back to
`git show` / `git diff` / reading files directly, same as Step 1's scope
resolution.

Invoke `/thermo-nuclear` against the resolved scope. Apply full standards:
ambitious code-judo restructuring, 1k-line file smell, spaghetti branching,
boundary/type cleanliness, canonical-layer leaks, orchestration atomicity —
see that skill for complete rubric. Don't water down for this skill.

Then invoke the ponytail complexity pass over the same scope: `/ponytail-review`
for a commit/PR/range (diff scope), `/ponytail-audit` for a directory
(whole-tree scope). This pass hunts a different axis than thermo-nuclear —
over-engineering, dead flexibility, reinvented stdlib/native code. It
complements thermo-nuclear rather than duplicating it.

## Step 4: Log every finding to backlog

Classify each finding the review surfaces:

- **fix** — the finding is an actual bug: incorrect behavior, not just
  structure.
- **refactor** — the finding is structural: spaghetti branching, canonical-
  layer leak, 1k-line-file smell, orchestration atomicity, or any other
  restructuring thermo-nuclear calls for that doesn't change behavior. Every
  ponytail-pass finding (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`) is
  structural by definition — classify these as refactor too.

Then append each via the CLI (it handles file creation and section
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

The description under the title should be as exhaustive as the finding
warrants. `Scope`/`Location`/`Finding`/`Preferred remedy` are that
description's internal structure, not a separate schema.

Log every finding that clears either pass's bar — thermo-nuclear's or
ponytail's. Don't filter down to only the scariest one. Don't pad the
file with cosmetic nits neither skill would have raised itself. Write one
entry per finding, appended in the order the reviews produced them.

## Step 5: Report back

Tell the user:

- The resolved scope reviewed.
- How many findings were logged (net-new lines/entries vs. the Step 2 baseline).
- The path to the backlog index written to.
- Zero findings: say clearly that the review passed both thermo-nuclear's
  and ponytail's approval bar with no logged issues. Don't write an empty
  entry just to prove the skill ran.
