---
name: radin-plan
description: |
  Write a step-by-step implementation plan for one backlog entry, without
  touching code. Scope is one task (a title/keyword), not the whole backlog.
  Use for /radin-plan, "plan this backlog entry", "write a plan for X before
  we execute it". radin-execute delegates here for any entry too complex to
  implement directly.
---
# Plan a Backlog Entry

Turn one backlog entry into one or more implementation plans, without
writing any code. Runs inline in whichever context invokes it. When the
invoking context cannot reach the user (e.g. radin-execute's planning
sub-agent), the caller says so; every question below then takes the
non-destructive branch marked "non-interactive". Such a run also cannot be
notified when a background task finishes, so `/grilling` and `/research` are
interactive-only here — waiting on either hangs the caller. Each
"non-interactive" branch below says what to do instead.

## Step 1: Resolve project namespace

All backlog reads/writes go through the shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh` — never hand-edit the backlog's
index or task files, or compute their paths yourself. Get the paths (also
creates the state/plans/reviews/tasks directories):

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" env
```

Read `REPO_ROOT`, `NAMESPACE_DIR`, `BACKLOG_INDEX`, `BACKLOG_TASKS_DIR` from
its output. Re-run this line in any later Bash call that uses them.

## Step 2: Resolve the task scope

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" find "<scope id/title/keyword>"
```

It prints one `id<TAB>category<TAB>title<TAB>file` line per match (exact id
first, then exact title, else substring on title).

- **One match**: use it.
- **Several**: list them and ask which one. Non-interactive: report the
  candidates and stop.
- **None** (interactive only): the task isn't in the backlog yet. Create it
  without asking — classify into `feat`/`fix`/`chore`/`refactor` (rubric in
  `skills/radin-record/SKILL.md`), then:

  ```bash
  bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <category> "<short title>" <<'EOF'
  <the task as the caller stated or clearly implied it, and why it matters
  if not already obvious>
  EOF
  ```

  Report the new entry, then continue with it as the scoped entry.
  Non-interactive: the scope always came from an existing entry, so no
  match means backlog drift — report and stop instead of writing a
  duplicate.
- **Already planned**: `radin-backlog.sh meta "<id>"` prints one
  `plan<TAB><path>` line per existing pointer. If any, show the path(s) and
  ask whether to re-plan (overwrite) or stop. Stop unless confirmed.

Record the entry's `id` and `title`; the id is the `parent_id`.

## Step 3: Judge whether the scope should split

Invoke `/ponytail` and apply its ladder: does this entry need more than one
plan? Lean toward NOT splitting — split only when the entry genuinely
bundles multiple unrelated, independently plannable changes.

This is a judgment call about the user's own task, so surface it.
Interactive: state your read (split or not, and why) and confirm it, using
`/grilling` when the entry's scope is genuinely unclear. Non-interactive:
take the default (no split) without asking.

- **Not splitting**: the sub-task list is the entry itself.
- **Splitting**: show the proposed sub-tasks (short titles, one-line
  description each, full coverage, no overlap) and confirm. Confirmed or
  edited: use that list. Rejected: fall back to the single-item list.

## Step 4: Write each plan

The entry's file (`$BACKLOG_TASKS_DIR/<parent_id>.md`) never moves, so no
re-resolution is needed between sub-tasks. For each sub-task, in order:

1. Read the entry's file. A sub-task from a split has only its one-line
   Step 3 description as scope — plan just that part.
2. Explore the codebase: structure, affected files, patterns, constraints.
   If `code-review-graph` is wired for this repo, use its MCP tools
   (`semantic_search_nodes`, `get_impact_radius`, `query_graph`) before
   Grep/Glob/Read. Prefer `rtk`-wrapped commands when `command -v rtk`
   succeeds. If the plan hinges on third-party API or library behavior
   local code can't confirm, invoke `/research` against primary sources
   first — never guess at external behavior. Non-interactive: `/research`
   spawns a background agent whose result cannot reach you, so stop and
   report the unconfirmed external behavior instead of guessing or waiting.
3. Invoke `/ponytail` and apply its ladder to produce the plan:
   - The minimum files to touch.
   - The concrete change in each file.
   - Order of operations, where it matters.
   - How to verify (tests/checks to run) — lazy code without its check is
     unfinished.

   Surface every open question the plan raised. Interactive: invoke
   `/grilling` on the entry's open aspects — it walks the decision tree one
   question at a time, defers facts to repo exploration, and won't finalize
   until understanding is confirmed. The plan you hand off must leave zero
   decisions to whoever executes it. Non-interactive: an unresolvable
   question stops the run — report it rather than plan around it.
4. Save the plan at `$NAMESPACE_DIR/plans/<sub-task-id>.md`.
5. Insert the pointer via the CLI (appends `**Plan:** <path>` to the task's
   file, after any earlier `**Plan:**` lines):

   ```bash
   bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add-plan "<parent_id>" "$NAMESPACE_DIR/plans/<sub-task-id>.md"
   ```

6. Report: `✅ <sub-task-id> planned. Plan: <path>.`

Planning and executing are separate tools: edit no source file, run no
build/test, create no commit anywhere in this skill. Never touch the scoped
task's file beyond the appended `**Plan:**` line(s), and never touch any
other task's file.

## Step 4.5: Review each plan before handing it off

A plan is a proposal — review it before `radin-execute` builds on it. For
each plan file just written:

1. Invoke `/thermo-nuclear` against the plan file's content (not the
   codebase): does the proposed approach itself carry a structural issue
   the rubric flags?
2. Invoke `/ponytail-review` against the same file: speculative
   flexibility, reinvented stdlib, single-caller layers?
3. Fix each finding by editing the plan file in place — the fix belongs in
   the plan itself, nothing goes to the backlog (unlike `radin-review`,
   this plan hasn't executed yet, so there is no review record to keep).
4. Zero findings: leave the file untouched.

## Step 5: Report back

```
✅ Entry planned.

| Sub-task | Plan | Review findings |
|------|------|------|
| <id> | $NAMESPACE_DIR/plans/<id>.md | <count of fixes applied, or "none"> |

Next: radin-execute (or a human) can implement from the plan(s) above.
```
