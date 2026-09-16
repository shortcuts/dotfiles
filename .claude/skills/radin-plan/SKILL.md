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

Turn one backlog entry into one or more implementation plans, without writing
any code. It runs inline in whichever context invokes it. A caller that cannot
reach the user says so in its prompt; the branches below marked
"non-interactive" are then the defaults, and anything only the user could
settle is reported and stops the run.

## Step 1: Resolve the task scope

```bash
radin backlog plan-target "<scope id/title/keyword>"
```

It prints `id`/`title`/`task_file`/`plan_file` lines, plus one
`plan<TAB><path>` line per plan the entry already has. Route on its exit code:

- **0**: resolved and unplanned. Use it.
- **1**: nothing matches. The task isn't in the backlog yet: classify it into
  `feat`/`fix`/`chore`/`refactor` (rubric in `skills/radin-record/SKILL.md`),
  create it without asking, then re-run `plan-target` on the printed id.

  ```bash
  radin backlog add <category> "<short title>" <<'EOF'
  <the task as the caller stated or clearly implied it, and why it matters
  if not already obvious>
  EOF
  ```

  Non-interactive: the scope always came from an existing entry, so no match
  means backlog drift. Report and stop instead of writing a duplicate.
- **2**: several entries match; it prints them as `candidate` lines on stderr.
  Ask which one. Non-interactive: report the candidates and stop.
- **3**: already planned; the `plan` lines are the existing paths. Show them and
  ask whether to re-plan (overwrite) or stop. Stop unless confirmed.

## Step 2: Judge whether the scope should split

Invoke `/ponytail:ponytail` and apply its ladder: does this entry need more than one
plan? Lean toward NOT splitting. Split only when the entry genuinely
bundles multiple unrelated, independently plannable changes.

Interactive: state your read (split or not, and why) and confirm it.
Non-interactive: take the default (no split) without asking.

- **Not splitting**: the sub-task list is the entry itself.
- **Splitting**: show the proposed sub-tasks (short titles, one-line
  description each, full coverage, no overlap) and confirm. Confirmed or
  edited: use that list. Rejected: fall back to the single-item list.

## Step 3: Write each plan

Step 1 printed `task_file` and `plan_file`; a task's file never moves, so
neither is re-resolved between sub-tasks. For each sub-task, in order:

1. Read the entry's file. A sub-task from a split has only its one-line
   Step 2 description as scope, so plan just that part.
2. Explore the codebase: structure, affected files, patterns, constraints.
   Use `codebase-memory-mcp`'s MCP tools before Grep/Glob/Read: `get_architecture` for the shape of an unfamiliar area,
   `search_graph` to find the symbols in scope, `trace_path` for every
   caller and callee the plan will touch, `get_code_snippet` to read one
   function, `query_graph` (after `get_graph_schema`) for anything
   Cypher-shaped. `index_repository` first when `list_projects` doesn't list
   this repo — a graph hit is a pointer: read the file before you cite or edit it, and never conclude something is absent from an empty result.
   Prefer `rtk`-wrapped commands when `command -v rtk`
   succeeds, and `headroom loc` for the shape of a repo you have not seen
   before when `command -v headroom` succeeds. If the plan hinges on
   third-party API or library behavior local code can't confirm, invoke
   `/mattpocock-skills:research` against primary sources first and never guess
   at external behavior. Non-interactive: that skill spawns its own agent whose
   result may not come back, so report the unconfirmed behavior and stop.
3. Invoke `/ponytail:ponytail` and apply its ladder to produce the plan. When
   the plan has to place a new module boundary or reshape an interface, invoke
   `/mattpocock-skills:codebase-design` for that part instead of inventing
   your own vocabulary for it. The plan states:
   - The minimum files to touch.
   - The concrete change in each file.
   - Order of operations, where it matters.
   - How to verify (tests/checks to run), because lazy code without its
     check is unfinished.

   Surface every open question the plan raised. The plan you hand off must
   leave zero decisions to whoever executes it. Non-interactive: an
   unresolvable question stops the run, so report it rather than plan around
   it.
4. Save the plan at the `plan_file` path Step 1 printed. For a sub-task from a
   split, re-run `plan-target "<id>" "<sub-slug>"` with the sub-task's short
   title in lowercase-hyphen form and use the `plan_file` it prints.
5. Insert the pointer via the CLI (appends `**Plan:** <path>` to the task's
   file, after any earlier `**Plan:**` lines):

   ```bash
   radin backlog add-plan "<id>" "<the plan_file path>"
   ```

6. Report: `✅ <id> planned. Plan: <path>. Review findings: <n or none>.` The
   count comes from Step 4, so write this line after that sub-task's review
   pass, not before it.

Planning and executing are separate tools: edit no source file, run no
build/test, create no commit anywhere in this skill. Never touch the scoped
task's file beyond the appended `**Plan:**` line(s), and never touch any
other task's file.

## Step 4: Review each plan before handing it off

A plan is a proposal, so review it before `radin-execute` builds on it. For
each plan file just written:

1. Invoke `/thermo-nuclear` against the plan file's content (not the
   codebase): does the proposed approach itself carry a structural issue
   the rubric flags?
2. Invoke `/ponytail:ponytail-review` against the same file: speculative
   flexibility, reinvented stdlib, single-caller layers?
3. Fix each finding by editing the plan file in place. The fix belongs in
   the plan itself, and nothing goes to the backlog.
4. Zero findings: leave the file untouched.

## Step 5: Report back

One line per plan, as Step 3's step 6 already printed it, then:

`Next: radin-execute (or a human) can implement from the plan(s) above.`
