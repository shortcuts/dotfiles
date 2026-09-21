---
name: radin-review
description: |
  Review a scope (commit, PR, directory, or a range like "since yesterday") on
  two axes — Standards (does the code follow this repo's rubrics?) and Spec
  (does it do what the originating backlog entry asked for?) — triage the
  findings with the user, and log the ones they keep as backlog entries.
  Use for /radin-review, "review and log to backlog", "audit this
  commit/PR/directory and file backlog entries".
---
# Review to Backlog

Run the strict review passes against a caller-specified scope and persist
every finding the user agrees to as a backlog entry instead of terminal
output. That leaves a durable backlog `radin-execute` (or a human) works
through later.

Two **axes** carry the review, and they stay separate end to end:

- **Standards** — does the scope follow the rubrics this repo documents?
- **Spec** — does the scope do what the originating backlog entry or its plan
  asked for?

A non-interactive caller cannot be reached and has no `AskUserQuestion`. Each
step below names its own arm only where the two arms differ.

## Step 1: Resolve scope argument

Resolve the argument (or its absence) via the shared CLI. Don't probe
git/gh by hand:

```bash
radin scope [<arg>]
```

Route on exit code:

- **0**: resolved. It prints `type`/`scope`/`command`/`passes` lines.
- **1**: not a commit, PR, directory, or range. A date phrase (`since
  yesterday`, `last week`) is the one exit 1 worth a second try: turn it into a
  revision with
  `git log --since="<phrase>" --format=%H | tail -1`
  (not `log -1 ... --reverse`: `-1` applies before `--reverse`, so it returns
  the newest commit in the window, not the oldest) and re-run
  `radin scope "<that hash>~1..HEAD"`, so the diff command still comes from
  the CLI. Every other exit 1 is unresolvable: report it and stop.
- **2**: ambiguous (candidates on stderr, e.g. both a PR number and a
  directory). Interactive: ask which one. Non-interactive: report both
  readings and stop.

State the resolved scope in one line before proceeding, e.g.
`Scope: commit a1b2c3d` or `Scope: directory src/auth/`. Step 4 invokes exactly
the skills the `passes` line names.

Capture both inputs once, here:

- **The diff command.** The `command` line is the scope's one diff command.
  Record it verbatim and paste that same string into every later Bash call and
  both briefs.
- **The commit list.** `git log <the scope's range> --format='%H %s'` for a
  `commit`, `range` or `branch-diff` type;
  `gh pr view <n> --json commits --jq '.commits[].oid'` for a `pr`. A `dir`
  scope has no commit list, and both briefs say so.

## Step 2: Confirm there is something to review

The scope has to have content before either axis runs. A bad ref already
failed in Step 1 — `radin scope` `git rev-parse --verify`s every revision it
emits — so what is left to assert is that the scope is non-empty. Assert it
here, not inside two axes:

- `commit`, `pr`, `range`, `branch-diff`: run Step 1's `command` verbatim,
  piped to `wc -l`. Zero lines means an empty diff.
- `dir`: `find <the scope path> -type f -print -quit` prints nothing when the
  directory holds no file.

Empty either way: report "nothing to review in `<scope>`" and stop. Log
nothing, and write no backlog entry to prove the skill ran.

## Step 3: Resolve the spec

The Spec axis reviews against the originating backlog entry or its plan. Work
these rungs in order and stop at the first that yields a spec:

1. **The invoking prompt named one** — a backlog id, a title, or a path. For an
   id or title:
   `radin backlog field "<it>" TASK_FILE` and
   `radin backlog field "<it>" PLAN_PATHS` (its exit 1 means no plan; the
   task file alone is then the spec). For a path: that file is the spec.
2. **The scope's commits match a completed task.** Once `radin-execute`
   finishes a task, `task-done` deletes the entry and its task file, so the id
   no longer resolves — but `completed.json` still maps id to commit, and the
   plan survives under `plans/`:

   ```bash
   source <(radin backlog env --export)
   radin state completed-list "$NAMESPACE_DIR/state/completed.json"
   ```

   It prints `id<TAB>commit` per completion. Intersect those commits with Step
   1's commit list. For each matched id, the spec is
   `$NAMESPACE_DIR/plans/<id>.md` when that file exists. A matched id with no
   plan file yields no spec — an id slug is too thin to review a diff against.
   Several matched ids: every one of their plan files is the spec, and the axis
   covers all of them.
3. **Ask.** Interactive only: one `AskUserQuestion` offering the top entries
   from `radin backlog list` as options, with the tool's free-text field
   carrying a path the user types instead. An answer of "there isn't one" falls
   to rung 4.
4. **Skip.** No spec: the Spec axis does not run. Say so once here, name it
   `no spec available` in Step 5's `## Spec` section, and carry it into Step 9's
   report. A non-interactive caller arrives here directly from rung 2, since
   rung 3 cannot run for it.

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

Three rules bind what survives that test:

- **Noise suppression.** Skip anything tooling already enforces — a formatter's
  or linter's job is not a finding.
- **The repo overrides.** A rubric this repo documents wins over a pass's
  generic judgement; where the repo endorses what a pass would flag, the
  finding is suppressed.
- **Judgement, labelled.** A structural finding is a labelled heuristic
  ("possible <name>"), and the label survives into the entry body — these
  findings become backlog entries an agent later acts on without the review in
  front of it. A breach of a documented repo rubric may be stated hard.

## Step 4: Run both axes

Interactive caller: dispatch both axes in one message as two parallel
sub-agents, so neither pollutes the other's context.

Non-interactive caller: run both briefs inline, Standards first, same briefs
and same caps. A non-interactive `radin-review` is itself a sub-agent —
`radin-execute`'s Phase 6 dispatches it that way — and a sub-agent cannot rely
on getting a spawned agent's result (`docs/technical-constraints.md`,
"Sub-agents cannot reach the user"). Inline always lands.

Each brief is self-contained: paste in full everything that exists only in this
skill's context — the resolved scope line, Step 1's `command` string and commit
list verbatim, and the whole `Scope discipline` section. Material on disk (the
spec's task file and plan files) goes in as an absolute path with "read it in
full before reviewing"; the sub-agent's `Read` is the access upstream's
paste-in-full rule exists to provide.

**Standards brief.**

Where the working tree **is** the scope — a `dir` or `branch-diff` type — start
with `codebase-memory-mcp`'s `detect_changes` (git diff mapped to affected
symbols, with blast radius and risk classification), then `trace_path` on the
symbols it flags and `get_code_snippet` to read them: risk-scored impact beats
reading a raw diff cold — a graph hit is a pointer: read the file before you
cite or edit it, and never conclude something is absent from an empty result.
For a `commit`, `pr` or `range` scope `detect_changes` reads the wrong tree, so
run Step 1's `command` and read the files it names instead; never check a commit
out to satisfy a tool.

Wrap the scope-content commands (`git show`, `git diff`, a test run) in `rtk`
when `command -v rtk` succeeds: a raw diff is the largest thing this axis
reads.

Invoke `/thermo-nuclear` against the scope, then every skill on Step 1's
`passes` line. Those passes hunt a different rubric from thermo-nuclear:
over-engineering, dead flexibility, reinvented stdlib/native code. A directory
scope adds the debt pass, which harvests the `ponytail:` shortcut comments
already in that code so the deferrals become triageable findings.

Report — per file/hunk where relevant — (a) every place the scope breaks a
rubric this repo documents: cite the rubric, file and rule; and (b) every
structural finding the passes raise: name it and quote the hunk. Cite
`path:line` for each. A documented repo rubric overrides a pass's generic
judgement, and a pass finding is a labelled judgement call. Skip anything
tooling already enforces. Under 400 words.

**Spec brief.** Skipped entirely when Step 3 reached rung 4.

Report: (a) requirements the spec asked for that are missing or only partly
implemented; (b) behaviour in the scope that the spec never asked for (scope
creep); (c) requirements that look implemented but whose implementation looks
wrong. Quote the spec line for each finding, and cite the `path:line` the
finding lands on. Skip anything tooling already enforces. Under 400 words.

The 400-word cap binds a sub-agent's report only; this skill's own prose is
uncapped.

## Step 5: Relay both reports

Present both reports under `## Standards` and `## Spec` headings, verbatim or
lightly cleaned, before any triage. Merge nothing and rerank nothing across the
two: the separation is the point (see *Why two axes*) — relay them side by side
as the two axes reported them. Step 3 rung 4 reached: `## Spec` says
`no spec available` and nothing else.

## Step 6: Filter, classify, triage

Nothing reaches the backlog until the user agrees to it. Both axes' citations
go through one filter, which drops the out-of-scope findings:

```bash
printf '%s\n' "<path:line per finding, one per line>" |
  radin scope --in-scope [<the same scope arg as Step 1>]
```

Keep the findings on the `in` lines, drop the `out` ones, and carry the
`dropped` count into Step 9's report. Cite one line per finding; for a range,
cite its first line.

A Spec finding about missing behaviour has no line of its own: cite the
in-scope line the requirement should have landed on — the hunk that implements
the partial behaviour, or the hunk nearest to where it belongs. Scope-creep and
wrong-implementation findings always have a line. A finding with genuinely no
in-scope line stays in Step 5's `## Spec` relay and is named in Step 9's report
as unlogged.

Then classify each survivor. This is a rule, not a judgment:

- **fix**: incorrect behavior. On the Spec axis, that is a missing, partial or
  wrongly-implemented requirement.
- **refactor**: everything else — anything thermo-nuclear's rubric flags
  without a behavior change, every ponytail finding
  (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`), and Spec-axis scope creep
  (behaviour nobody asked for).

Print the numbered list — one line each: number, axis, category, location, the
finding in a clause. It is the triage handle for what Step 5 already printed,
so it carries no detail the relay above carries. Print every Standards finding
first in the order that axis reported them, then every Spec finding in its own
order; that ordering is the axes' order, not a ranking. Mark the ones you
recommend tackling, within each axis. Recommend on severity and effort, not on
count; recommending all of them is a valid answer when they all earn it.

Then gate on `AskUserQuestion` (single select):

1. **Recommended only** — log the ones you marked.
2. **All** — log every in-scope finding.

The tool's own free-text field already covers a hand-picked subset, so don't
add a third option for it. A free-text answer names the numbers you printed;
read it as that subset and nothing more, and restate the subset in one line
before continuing.

**Non-interactive caller**: skip this gate and Step 7, log every in-scope
finding, and say in Step 9's report that no triage happened.

## Step 7: Optional refinement pass

Non-interactive: skipped (Step 6).

Ask one yes/no on `AskUserQuestion`: refine the selected findings before
logging?

**No**: go to Step 8 with the entries as reviewed.

**Yes**: invoke `/mattpocock-skills:grilling` over the selected findings, one
finding at a time, in order. Name the finding and what is open about it
(scope too wide, remedy wrong, priority off, a constraint the review cannot
see). Fold each settled answer into that finding's category, title, and body
before moving to the next finding. Drop a finding the user argues away, and
say so.

## Step 8: Log the agreed findings to backlog

The body carries what a sub-agent with no review context needs to act on the
finding. Carry Step 7's refinements into it.

Write a section only when it carries content a downstream agent acts on; a
label with nothing under it goes nowhere.

Append each via the CLI:

```bash
radin backlog add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed, from Step 1>
**Location:** <the cited path:line>
**Finding:**
<the problem as the review stated it: direct, specific. A Spec-axis finding
opens with the spec line the brief quoted.>
**Preferred remedy:**
<the concrete restructuring suggested>
**Acceptance:** <one flat `- ` bullet per criterion below this line, only when
Step 7's refinement settled a checkable outcome — never synthesise one
(`radin-record`'s Step 5 owns that rule).>
EOF
```

Log one entry per agreed finding, in the order presented. Log nothing the
user discarded.

## Step 9: Report back

- The resolved scope reviewed.
- The spec the Spec axis ran against, as its path, or `no spec available`.
- The entries logged, one line each — these are the `add` calls you just made.
- Findings the user discarded, as a count.
- Spec findings dropped for having no in-scope line, as a count.
- The `dropped` count from Step 6's filter, in one line with no detail, when it
  is not 0.
- The backlog index path.
- Zero findings: say the review passed both axes, and don't write an empty
  entry to prove the skill ran. Same when the user discarded all of them —
  report that, and write nothing.

End with one line: total findings per axis, and the worst issue within each
axis. Give each axis its own worst, never one winner across the two — that is
the reranking the separation exists to prevent.

## Step 10: Backlog now, or execute now

Logged entries stay in the backlog either way — this only decides what
happens next. Ask one `AskUserQuestion` (single select):

1. **Leave in backlog** — stop here.
2. **Tackle now** — invoke `/radin-execute`. It prioritizes and executes the
   whole backlog, not only these entries. Say that before it runs.

Skip this step when nothing was logged, and when the caller is
non-interactive.

## Why two axes

A change can pass one axis and fail the other:

- Code that satisfies every rubric but implements the wrong backlog entry →
  **Standards pass, Spec fail.**
- Code that does exactly what the entry asked but breaks this repo's
  conventions → **Spec pass, Standards fail.**

radin has the spec upstream tooling has to hunt for: the backlog entry, or the
plan `radin-plan` wrote from it. Reporting the axes separately stops one from
masking the other, which is why Step 5 relays them side by side and Step 6
tags every finding with the axis that raised it.
