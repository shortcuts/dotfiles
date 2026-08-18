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

Run the strict review passes against a caller-specified scope and persist
every finding as a backlog entry instead of terminal output — a durable
backlog that `radin-execute` (or a human) works through later.

## Step 1: Resolve scope argument

Resolve the argument (or its absence) via the shared CLI — don't probe
git/gh by hand:

```bash
bash "$HOME/.claude/.radin/lib/radin-scope.sh" [<arg>]
```

It settles commit hashes, PR references, directory paths, and the
no-argument default (working branch's diff against its merge-base with
main/master). Route on exit code:

- **0** — resolved. It prints `type`/`scope`/`command` lines; run the
  printed command to get the scope's content.
- **1** — not a commit, PR, or directory. A natural-language range ("the
  last 5 commits", "since yesterday") is yours to translate into concrete
  `git log`/`git diff` invocations. Anything else: report it as
  unresolvable.
- **2** — ambiguous (candidates on stderr, e.g. both a PR number and a
  directory). Interactive: ask which one. Non-interactive (e.g.
  radin-execute's reviewer sub-agent): report both readings and stop — the
  caller retries with an unambiguous scope or resolves it with the user.

State the resolved scope in one line before proceeding, e.g.
`Scope: commit a1b2c3d` or `Scope: directory src/auth/`.

## Scope discipline

The resolved scope is the whole review surface. A finding qualifies only if
the scope introduced it.

- **Diff scope** (commit, PR, branch, range): only lines the diff adds or
  changes. Code that already existed and the diff left alone is out of
  scope, even in a file the diff touches, even when it is worse than what
  the diff added. Read surrounding code for context, never to find
  findings.
- **Directory scope**: every file under that path, nothing outside it.
- Out-of-scope problem the diff makes worse: report it only when the
  in-scope change is what makes it wrong, and say which changed line
  causes that.

A finding you cannot tie to a specific in-scope line is not a finding here,
however real the problem is.

## Step 2: Record backlog baseline

Backlog writes go through
`$HOME/.claude/.radin/lib/radin-backlog.sh` — never hand-edit the index or
task files. Record the baseline for the end-of-run count:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" count
```

## Step 3: Run reviews

If `code-review-graph` is installed and wired for this repo, use
`detect_changes` + `get_review_context` against the scope first —
risk-scored context beats reading raw diffs cold. Otherwise fall back to
`git show`/`git diff`/reading files.

Invoke `/thermo-nuclear` against the scope.

Then invoke the ponytail pass over the same scope: `/ponytail-review` for a
diff scope (commit/PR/range), `/ponytail-audit` for a directory. It hunts a
different axis — over-engineering, dead flexibility, reinvented
stdlib/native code — and complements thermo-nuclear.

Name the exact scope in each invocation and restate the scope discipline
above. It narrows what both rubrics look at, never how hard they look.

## Step 4: Log every finding to backlog

For a diff scope, check each finding's cited line against the diff before
classifying anything — both passes read whole files, so they surface findings
this skill must drop.

Classify each finding:

- **fix** — an actual bug: incorrect behavior, not just structure.
- **refactor** — structural: anything thermo-nuclear's rubric flags without
  a behavior change, and every ponytail finding
  (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`) by definition.

Append each via the CLI:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed, from Step 1>
**Location:** <file path(s) and function/line if applicable>
**Finding:**
<the problem, stated the way the review skill states it — direct, specific>
**Preferred remedy:**
<the concrete restructuring suggested>
EOF
```

Those four labels are the description's internal structure, not a separate
schema; make the body as exhaustive as the finding warrants.

Log every finding that clears either pass's bar, one entry per finding, in
the order produced. Skip cosmetic nits neither skill would raise itself.

## Step 5: Report back

- The resolved scope reviewed.
- Findings logged (net-new vs. the Step 2 baseline).
- Count of findings dropped as out of scope, if any — one line, no detail.
- The backlog index path.
- Zero findings: say the review passed both bars — don't write an empty
  entry to prove the skill ran.
