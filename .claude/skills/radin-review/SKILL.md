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

Review a caller-specified scope on two axes, and persist every finding the
user keeps as a backlog entry instead of terminal output. That leaves a
durable backlog `radin-execute` (or a human) works through later.

- **Standards** — does the scope follow the rubrics this repo documents?
- **Spec** — does the scope do what the originating backlog entry or its plan
  asked for?

The axes stay separate end to end, for the reason
`/mattpocock-skills:code-review` states under *Why two axes*. radin supplies
the spec that skill has to hunt for: the backlog entry, or the plan
`radin-plan` wrote from it.

**Sub-agent caller** — `radin-execute`'s Phase 6 dispatches this skill that
way, and a sub-agent reaches neither the user nor a spawned agent's result
(`docs/technical-constraints.md`): run every step inline, Standards axis
first, skip each `AskUserQuestion`, log every in-scope finding, and say in
Step 6's report that no triage happened.

## Step 1: Resolve the scope

```bash
radin scope [<arg>]
```

It prints `type`/`scope`/`command`/`passes` lines, and Step 3 invokes exactly
the skills the `passes` line names. Route on its exit code:

- **1**: not a commit, PR, directory, range, or `since <date>`. Report it and
  stop.
- **2**: ambiguous, candidates on stderr (e.g. both a PR number and a
  directory). Ask which one; a sub-agent caller reports both readings and
  stops.

State the resolved scope in one line — `Scope: commit a1b2c3d`,
`Scope: directory src/auth/` — then capture both inputs the axes need, here
and once:

- **The diff command.** The `command` line is the scope's one diff command.
  Record it verbatim and paste that same string into every later Bash call and
  both briefs.
- **The commit list.** `git log <the scope's range> --format='%H %s'` for a
  `commit`, `range` or `branch-diff` type;
  `gh pr view <n> --json commits --jq '.commits[].oid'` for a `pr`. A `dir`
  scope has no commit list, and both briefs say so.

Run the `command` before either axis starts. No output — for a `dir` scope, no
file under the path — means report "nothing to review in `<scope>`" and stop.
Write no backlog entry to prove the skill ran.

## Step 2: Resolve the spec

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
   radin scope --tasks [<the same scope arg as Step 1>]
   ```

   It prints one matched task id per line, and nothing when no commit in scope
   came from a task — a `dir` scope always. For each matched id,
   `radin state completed-show "$NAMESPACE_DIR/state/completed.json" "<id>"`
   names the plan the task ran against and the branch it ran on: its `plan`
   line carries the recorded paths, comma-separated, and those files are the
   spec. Empty `plan` line (a completion recorded before provenance existed):
   `$NAMESPACE_DIR/plans/<id>.md` when that file exists — an id slug alone is
   too thin to review a diff against. Several matched ids: every one of their
   plan files is the spec, and the axis covers all of them.
3. **Ask.** One `AskUserQuestion` offering the top entries from
   `radin backlog list` as options, with the tool's free-text field
   carrying a path the user types instead. "There isn't one" falls to rung 4.
4. **Skip.** No spec: the Spec axis does not run. Say so once here, and report
   `no spec available` for that axis in Steps 3 and 6. A sub-agent caller
   arrives here straight from rung 2.

## Step 3: Run both axes

Dispatch both axes in one message as two parallel sub-agents, so neither
pollutes the other's context.

Each brief is self-contained: paste in full the resolved scope line, Step 1's
`command` string and commit list verbatim, and the citation rule below. The
spec goes in as an absolute path with "read it in full before reviewing"; the
sub-agent's `Read` is the access that paste-in-full rule exists to provide.

> Every finding cites one `path:line` the scope introduced: for a diff scope
> the lines it adds or changes, for a `dir` scope the files under that path.
> Read surrounding code for context, never to find findings. A problem that
> predates the scope qualifies only when a changed line is what makes it wrong,
> and that changed line is the citation. Skip anything a formatter or linter
> already enforces.

**Standards brief.** Invoke `/thermo-nuclear` against the scope, then every
skill Step 1's `passes` line names. Report — per file/hunk where relevant —
(a) every place the scope breaks a rubric this repo documents: cite the
rubric, file and rule; and (b) every structural finding the passes raise: name
it and quote the hunk. A documented repo rubric overrides a pass's generic
judgement, and a pass finding stays a labelled judgement call
("possible <name>") — the label reaches the backlog entry an agent later acts
on without the review in front of it. Under 400 words.

**Spec brief.** Skipped entirely when Step 2 reached rung 4. Report: (a)
requirements the spec asked for that are missing or only partly implemented;
(b) behaviour in the scope that the spec never asked for (scope creep); (c)
requirements that look implemented but whose implementation looks wrong. Quote
the spec line for each finding, and cite the `path:line` it lands on. Under
400 words.

Relay both reports under `## Standards` and `## Spec` headings before any
triage, each axis in its own order and neither reranked against the other.

## Step 4: Filter, classify, triage

Nothing reaches the backlog until the user agrees to it. Both axes' citations
go through one filter, which drops the out-of-scope findings:

```bash
printf '%s\n' "<path:line per finding, one per line>" |
  radin scope --in-scope [<the same scope arg as Step 1>]
```

Keep the findings on the `in` lines, drop the `out` ones, and carry the
`dropped` count into Step 6. Cite one line per finding; for a range, its first
line. A Spec finding about missing behaviour cites the in-scope line the
requirement should have landed on — the hunk with the partial behaviour, or the
one nearest where it belongs. A finding with genuinely no in-scope line stays
in Step 3's relay, and Step 6 names it as unlogged.

Then classify each survivor. This is a rule, not a judgment: **fix** for
incorrect behavior — on the Spec axis, a missing, partial or wrongly
implemented requirement — and **refactor** for everything else, scope creep
included.

Print the survivors as a numbered list — number, axis, category, location, the
finding in a clause — every Standards finding first, then every Spec finding,
each in its own axis's order. It is the triage handle for what Step 3 already
printed, so it carries no further detail. Mark the ones you recommend
tackling, on severity and effort rather than count; recommending all of them
is a valid answer.

Then gate on `AskUserQuestion` (single select):

1. **Recommended only** — log the ones you marked.
2. **All** — log every in-scope finding.

A free-text answer names the numbers you printed; read it as that subset and
nothing more, and restate the subset in one line before continuing.

## Step 5: Log the agreed findings to backlog

The body carries what a sub-agent with no review context needs to act on the
finding:

```bash
radin backlog add <fix|refactor> "<short title>" <<'EOF'
**Scope:** <what was reviewed, from Step 1>
**Finding:**
<the problem as the review stated it: direct, specific. A Spec-axis finding
opens with the spec line the brief quoted.>
**Preferred remedy:**
<the concrete restructuring suggested>
EOF
radin backlog set-meta <id> location "<the cited path:line>"
```

Log one entry per agreed finding, in the order presented. Log nothing the
user discarded.

## Step 6: Report back

- The resolved scope reviewed, and the spec path or `no spec available`.
- The entries logged, one line each — these are the `add` calls you just made.
- Findings the user discarded, findings dropped as out of scope, and Spec
  findings dropped for having no in-scope line: three counts, no detail.
- The backlog index path.
- Zero findings: say the review passed both axes. Every finding discarded:
  report that. Either way, write no entry to prove the skill ran.

End with one line: total findings per axis, and the worst issue within each
axis. Give each axis its own worst, never one winner across the two — that is
the reranking the separation exists to prevent.
