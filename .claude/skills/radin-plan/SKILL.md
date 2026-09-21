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

- **2**: several entries match; it prints them as `candidate` lines on stderr.
  Ask which one.
- **3**: already planned; the `plan` lines are the existing paths. Show them and
  ask whether to re-plan (overwrite) or stop. Stop unless confirmed.

Non-interactive, for all three: report what `plan-target` printed and stop. The
scope came from an existing entry, so no match means backlog drift — the run
adds no entry, picks no candidate among several, and overwrites no plan.

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
2. Explore the repo to understand the current state of the codebase, if you
   haven't already: structure, affected files, patterns, constraints. Carry the
   project's own vocabulary into the plan — its glossary or domain-model doc
   where it has one — and respect any ADR covering the area you're touching.

   - Use `codebase-memory-mcp`'s MCP tools before Grep/Glob/Read:
     `get_architecture` for the shape of an unfamiliar area, `search_graph` to
     find the symbols in scope, `trace_path` for every caller and callee the
     plan will touch, `get_code_snippet` to read one function, `query_graph`
     (after `get_graph_schema`) for anything Cypher-shaped. Run
     `index_repository` first when `list_projects` doesn't list this repo — a graph hit is a pointer: read the file before you cite or edit it, and never conclude something is absent from an empty result.
   - Prefer `rtk`-wrapped commands when `command -v rtk` succeeds. Add
     `headroom loc` for the shape of a repo you have not seen before, when
     `command -v headroom` succeeds.
   - A plan hinging on third-party API or library behavior that local code
     cannot confirm: read the entry's `**Fact:**` lines and its `**Facts:**`
     file first, because an earlier invocation may already have answered it.
     - **Running in the user's own thread**: hand the question to the research
       companion, so its reading happens in the background while you plan the
       parts that do not hinge on the answer. Gate it:

       ```bash
       source <(radin backlog env --export)
       command -v claude >/dev/null 2>&1 &&
         claude plugin list 2>/dev/null |
         grep -q mattpocock-skills@claude-plugins-official
       ```

       Exit 0: invoke `/mattpocock-skills:research` with the question, naming
       `$NAMESPACE_DIR/state/facts/<task-id>.md` as the file to write its
       findings to. When it reports, record the answer so the next invocation
       reads it instead of re-researching:

       ```bash
       radin backlog append "<id>" <<'EOF'
       **Fact:** <the answer in one sentence, naming the source that owns it>
       **Facts:** <the state/facts path above>
       EOF
       ```

       Non-zero exit, or the skill asks you anything: drop it, never wait on
       it, and treat the question as unsettled from here — name it in the
       report and stop.
     - **Non-interactive**: the answer lies outside this repo, so report the
       question and stop. `radin-execute`'s router owns the research arm for it
       (`radin-execute-clarify.md`) and appends the answer to this task's file,
       so the next planning wave reads it and this stop is a pause, not a loss.
3. Sketch the seams at which the change will be tested. Prefer an existing seam
   to a new one, and use the highest seam available. If new seams are needed,
   propose them at the highest point you can. The fewer seams across the
   codebase, the better — the ideal number is one.

   Interactive: check with the user that these seams match their expectations,
   before anything is written.
   Non-interactive: record the seam you chose in the plan's `## Testing`
   section and write on.
4. Invoke `/ponytail:ponytail` and apply its ladder to produce the plan. When
   the plan has to place a new module boundary or reshape an interface, invoke
   `/mattpocock-skills:codebase-design` for that part instead of inventing
   your own vocabulary for it. Write it to the template below, section by
   section — the template is the output contract, and every plan radin writes
   has that shape.

   Non-interactive: synthesize the plan from the entry, the repo, and what this
   conversation already holds. A question none of those three answers is the
   report line that ends the run, not a decision to leave open in the plan.
5. Save the plan at the `plan_file` path Step 1 printed. For a sub-task from a
   split, re-run `plan-target "<id>" "<sub-slug>"` with the sub-task's short
   title in lowercase-hyphen form and use the `plan_file` it prints.
6. Insert the pointer via the CLI (appends `**Plan:** <path>` to the task's
   file, after any earlier `**Plan:**` lines):

   ```bash
   radin backlog add-plan "<id>" "<the plan_file path>"
   ```

7. Report: `✅ <id> planned. Plan: <path>. Review findings: <n or none>.` The
   count comes from Step 4, so write this line after that sub-task's review
   pass, not before it.

Planning and executing are separate tools, so this skill's whole output is the
plan file(s) it writes plus the one `**Plan:**` line the CLI appends to the
scoped task's file. Everything else in the tree stays exactly as you found it:
no source file edited, no build or test run, no commit, and no other task's
file touched. The one addition to the scoped task's file beyond that `**Plan:**`
line is the `**Fact:**`/`**Facts:**` pointer, when research ran.

### The plan template

Write a section only when it carries content a downstream agent acts on; a
label with nothing under it goes nowhere.

<plan-template>

```markdown
# Plan: <task title>

**Task:** `<task id>` — <the `task_file` path Step 1 printed>
**Reading this:** the entry holds the problem, the acceptance criteria and
every `**Decision:**` line; this plan holds the how and restates none of it.

## Outcome

<One or two lines: what is true of the codebase once this plan is implemented.>

## Decisions

<A numbered list: every choice the executor would otherwise have to make, each
one settled here. Each entry in the format:>

1. <The question> → <the settled answer>. Why: <one line>.

<Every claim about the current code carries its source inline — `path:line`, or
the read-only command that produced it. Every claim about third-party behavior
names the source that owns it — official docs, source code, a spec, or a
first-party API. A claim with no such source is an open question, so it ends
the run per Step 3's step 4 rather than entering a plan step.>

<A decision the executor has to invent is a defect in this plan.>

## Changes

<One entry per file to touch — the minimum set, no more:>

- `<path>` — <the concrete change, in prose: the symbols to touch and what
  becomes of each. No line numbers, and no pasted code.>

<Exception for code: a snippet that encodes a decision more precisely than
prose can — a schema, a type shape, a state machine, the exact string a test
asserts on. Inline it in the entry it belongs to, trimmed to the
decision-rich part.>

## Order

<The steps that must happen in a given order, numbered, each with the one line
saying why it gates the next — or "Any order." when nothing does.>

## Testing

**Seam:** <the seam from the Step 3 sketch, and why it's the highest available.>
**Prior art:** <an existing test in this repo whose shape the new test copies.>
**What to test:** <external behavior only — what a caller observes, never an
implementation detail.>

- [ ] <one line per check to run, as the command that runs it>

## Out of scope

<What a reader might expect here and this plan deliberately does not do, each
with where it does belong — or "Nothing — the entry's scope is covered in full
above.">
```

</plan-template>

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

## Step 5: Report back

One line per plan, as Step 3's step 7 already printed it, then:

`Next: radin-execute (or a human) can implement from the plan(s) above.`
