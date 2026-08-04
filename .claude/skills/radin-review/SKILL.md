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

The user passes one argument. It is one of:

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

The argument looks ambiguous (e.g. it could be a commit hash or a directory
name, or a PR number that doesn't resolve via `gh`) — check facts before
asking anyone: `git cat-file -t <arg>` (expect `commit`), `test -d <arg>`,
`gh pr view <arg>` all settle it without a question. Most "ambiguous"
arguments resolve this way.

Still ambiguous after checking facts — e.g. it resolves as both a valid
commit-ish and an existing directory:

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
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" show 2>/dev/null | wc -l
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
