---
name: radin-review
description: |
  Run a thermo-nuclear code quality review over a scope (commit, PR, directory,
  or a range like "since yesterday"), triage the findings with the user, and
  log the ones they keep as backlog entries instead of printing to terminal.
  Use for /radin-review, "review and log to backlog", "audit this
  commit/PR/directory and file backlog entries".
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
radin scope [<arg>]
```

Route on exit code:

- **0**: resolved. It prints `type`/`scope`/`command`/`passes` lines; run the
  printed command to get the scope's content.
- **1**: not a commit, PR, directory, or range. `last 3 commits`, `last commit`
  and `<rev>..<rev>` resolve as `type range`, so exit 1 means the argument names
  no revision the CLI can verify. A date phrase is the one case worth a second
  try: turn it into a revision with
  `git log --since="<phrase>" --format=%H | tail -1`
  (not `log -1 ... --reverse`: `-1` applies before `--reverse`, so it returns
  the newest commit in the window, not the oldest) and re-run
  `radin scope "<that hash>~1..HEAD"`, so the diff command still comes from
  the CLI. Anything else: report it as unresolvable and stop.
- **2**: ambiguous (candidates on stderr, e.g. both a PR number and a
  directory). Interactive: ask which one. Non-interactive: report both
  readings and stop.

State the resolved scope in one line before proceeding, e.g.
`Scope: commit a1b2c3d` or `Scope: directory src/auth/`. Keep the `passes` line;
Step 2 invokes exactly the skills it names.

## Scope discipline

The resolved scope is the whole review surface, and every finding cites one
in-scope line.

- **Diff scope** (commit, PR, branch, range): the lines the diff adds or
  changes. Code the diff left alone is out of scope, even in a file it touches,
  even when it is worse than what the diff added. Read surrounding code for
  context, never to find findings.
- **Directory scope**: every file under that path, nothing outside it.
- A problem that predates the scope qualifies only when a changed line is what
  makes it wrong, and that changed line is the finding's citation.

So there is one test, not two: no in-scope line to cite, no finding — however
real the problem is.

## Step 2: Run reviews

Where the working tree **is** the scope — a `dir` or `branch-diff` type — start
with `codebase-memory-mcp`'s `detect_changes` (git diff mapped to affected
symbols, with blast radius and risk classification), then `trace_path` on the
symbols it flags and `get_code_snippet` to read them: risk-scored impact beats
reading a raw diff cold — a graph hit is a pointer: read the file before you cite or edit it, and never conclude something is absent from an empty result.
For a `commit`, `pr` or `range` scope `detect_changes` reads the wrong tree, so
run Step 1's `command` and read the files it names instead; never check a commit
out to satisfy a tool.

Invoke `/thermo-nuclear` against the scope.

Wrap the scope-content commands (`git show`, `git diff`, a test run) in `rtk`
when `command -v rtk` succeeds: a raw diff is the largest thing this skill
reads.

Then invoke every skill on Step 1's `passes` line against the same scope.
Their findings go through Step 3's filter like every other. They hunt a
different axis from thermo-nuclear: over-engineering, dead flexibility,
reinvented stdlib/native code. A directory scope adds the debt pass, which
harvests the `ponytail:` shortcut comments already in that code so the
deferrals become triageable findings.

Name the exact scope in each invocation and restate the scope discipline
above. It narrows what both rubrics look at, never how hard they look.

## Step 3: Present findings and get agreement

Nothing reaches the backlog until the user agrees to it. First drop the
out-of-scope findings:

```bash
printf '%s\n' "<path:line per finding, one per line>" |
  radin scope --in-scope [<the same scope arg as Step 1>]
```

Keep the findings on the `in` lines, drop the `out` ones, and carry the
`dropped` count into Step 6's report. Cite one line per finding; for a range,
cite its first line.

Then classify each survivor. This is a rule, not a judgment:

- **fix**: incorrect behavior.
- **refactor**: everything else — anything thermo-nuclear's rubric flags
  without a behavior change, and every ponytail finding
  (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`).

Print the numbered list — one line each: number, category, location, the
finding in a clause. Mark the ones you recommend tackling. Recommend on
severity and effort, not on count; recommending all of them is a valid
answer when they all earn it.

Then gate on `AskUserQuestion` (single select):

1. **Recommended only** — log the ones you marked.
2. **All** — log every in-scope finding.

The tool's own free-text field already covers a hand-picked subset, so don't
add a third option for it. A free-text answer names the numbers you printed;
read it as that subset and nothing more, and restate the subset in one line
before continuing.

**Non-interactive caller**: skip this gate and Step 4, log every in-scope
finding, and say in Step 6's report that no triage happened.

## Step 4: Optional refinement pass

Non-interactive: skipped (Step 3).

Ask one yes/no on `AskUserQuestion`: refine the selected findings before
logging?

**No**: go to Step 5 with the entries as reviewed.

**Yes**: invoke `/mattpocock-skills:grilling` over the selected findings, one
finding at a time, in order. Name the finding and what is open about it
(scope too wide, remedy wrong, priority off, a constraint the review cannot
see). Fold each settled answer into that finding's category, title, and body
before moving to the next finding. Drop a finding the user argues away, and
say so.

## Step 5: Log the agreed findings to backlog

Four labels carry the body, and `**Acceptance:**` is an optional fifth. Make the
body as exhaustive as the finding warrants, and carry Step 4's refinements into
it. Append each via the CLI:

```bash
radin backlog add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed, from Step 1>
**Location:** <the cited path:line>
**Finding:**
<the problem as the review stated it: direct, specific>
**Preferred remedy:**
<the concrete restructuring suggested>
**Acceptance:** <one flat `- ` bullet per criterion below this line, only when
Step 4's refinement settled a checkable outcome. Omit the label otherwise, and
always on the non-interactive path where Step 4 does not run — never synthesise
one (`radin-record`'s Step 5 owns that rule).>
EOF
```

Log one entry per agreed finding, in the order presented. Log nothing the
user discarded.

## Step 6: Report back

- The resolved scope reviewed.
- The entries logged, one line each — these are the `add` calls you just made.
- Findings the user discarded, as a count.
- The `dropped` count from Step 3's filter, in one line with no detail, when it
  is not 0.
- The backlog index path.
- Zero findings: say the review passed both bars, and don't write an empty
  entry to prove the skill ran. Same when the user discarded all of them —
  report that, and write nothing.

## Step 7: Backlog now, or execute now

Logged entries stay in the backlog either way — this only decides what
happens next. Ask one `AskUserQuestion` (single select):

1. **Leave in backlog** — stop here.
2. **Tackle now** — invoke `/radin-execute`. It prioritizes and executes the
   whole backlog, not only these entries. Say that before it runs.

Skip this step when nothing was logged, and when the caller is
non-interactive.
