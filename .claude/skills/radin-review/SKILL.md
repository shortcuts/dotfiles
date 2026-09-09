---
name: radin-review
description: |
  Run a thermo-nuclear code quality review over a scope (commit, PR, directory,
  or a range like "since yesterday"), triage the findings with the user, and
  log the ones they keep as backlog entries instead of printing to terminal. Use for /radin-review, "review and log to
  backlog", "audit this commit/PR/directory and file backlog entries", "turn
  this review into a backlog".
---
# Review to Backlog

Run the strict review passes against a caller-specified scope and persist
every finding the user agrees to as a backlog entry instead of terminal
output. That leaves a durable backlog `radin-execute` (or a human) works
through later.

## Step 1: Resolve scope argument

Resolve the argument (or its absence) via the shared CLI. Don't probe
git/gh by hand:

```bash
bash "$HOME/.claude/.radin/lib/radin-scope.sh" [<arg>]
```

It settles commit hashes, PR references, directory paths, and the
no-argument default (working branch's diff against its merge-base with
main/master). Route on exit code:

- **0**: resolved. It prints `type`/`scope`/`command` lines; run the
  printed command to get the scope's content.
- **1**: not a commit, PR, or directory. A natural-language range ("the
  last 5 commits", "since yesterday") is yours to translate into concrete
  `git log`/`git diff` invocations. Anything else: report it as
  unresolvable.
- **2**: ambiguous (candidates on stderr, e.g. both a PR number and a
  directory). Interactive: ask which one. Non-interactive (e.g.
  radin-execute's reviewer sub-agent): report both readings and stop, so the
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
`$HOME/.claude/.radin/lib/radin-backlog.sh`. Never hand-edit the index or
task files. Record the baseline for the end-of-run count:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" count
```

## Step 3: Run reviews

If `code-review-graph` is installed and wired for this repo, use
`detect_changes` + `get_review_context` against the scope first, because
risk-scored context beats reading raw diffs cold. Otherwise fall back to
`git show`/`git diff`/reading files.

Invoke `/thermo-nuclear` against the scope.

Then invoke the ponytail pass over the same scope: `/ponytail:ponytail-review` for a
diff scope (commit/PR/range), `/ponytail:ponytail-audit` for a directory. It hunts a
different axis (over-engineering, dead flexibility, reinvented stdlib/native
code) and complements thermo-nuclear.

Name the exact scope in each invocation and restate the scope discipline
above. It narrows what both rubrics look at, never how hard they look.

## Step 4: Present findings and get agreement

Nothing reaches the backlog until the user agrees to it. First, drop the
out-of-scope findings yourself: for a diff scope, check each finding's cited
line against the diff, because both passes read whole files and surface
findings this skill must drop.

Then classify each survivor:

- **fix**: an actual bug, meaning incorrect behavior rather than structure.
- **refactor**: structural. That covers anything thermo-nuclear's rubric
  flags without a behavior change, and every ponytail finding
  (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`) by definition.

Print the numbered list — one line each: number, category, location, the
finding in a clause. Mark the ones you recommend tackling. Recommend on
severity and effort, not on count; recommending all of them is a valid
answer when they all earn it.

Then gate on `AskUserQuestion` (single select):

1. **Recommended only** — log the ones you marked.
2. **All** — log every in-scope finding.
3. **Let me pick** — the user names which to keep or discard, by number.

On option 3, read their answer and restate the surviving set in one line
before continuing. Iterate if they correct it.

**Non-interactive caller** (e.g. radin-execute's reviewer sub-agent, which
has no `AskUserQuestion`): skip this gate and Step 5, log every in-scope
finding, and say in Step 7's report that no triage happened.

## Step 5: Optional refinement pass

Ask one yes/no on `AskUserQuestion`: refine the selected findings before
logging?

**No**: go to Step 6 with the entries as reviewed.

**Yes**: invoke `/mattpocock-skills:grilling` over the selected findings, one
finding at a time, in order. Name the finding and what is open about it
(scope too wide, remedy wrong, priority off, a constraint the review cannot
see). Grilling asks the actual questions one at a time and won't finalize
until the answer is settled — don't restate a finding's problem back to the
user as a yes/no, and don't batch findings into one pass. Fold each settled
answer into that finding's category, title, and body before moving to the
next finding. Drop a finding the user argues away, and say so.

## Step 6: Log the agreed findings to backlog

Append each via the CLI:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed, from Step 1>
**Location:** <file path(s) and function/line if applicable>
**Finding:**
<the problem, stated the way the review skill states it: direct, specific>
**Preferred remedy:**
<the concrete restructuring suggested>
EOF
```

Those four labels are the description's own internal structure. Make the
body as exhaustive as the finding warrants, and carry Step 5's refinements
into it.

Log one entry per agreed finding, in the order presented. Log nothing the
user discarded.

## Step 7: Report back

- The resolved scope reviewed.
- Findings logged (net-new vs. the Step 2 baseline).
- Findings the user discarded, as a count.
- Count of findings dropped as out of scope, if any, in one line with no
  detail.
- The backlog index path.
- Zero findings: say the review passed both bars, and don't write an empty
  entry to prove the skill ran. Same when the user discarded all of them —
  report that, and write nothing.
