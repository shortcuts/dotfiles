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

It prints `id`/`title`/`task_file`/`plan_file` lines, plus a
`facts<TAB><path>` line when the entry carries one, plus one
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
plan? Split only when the entry bundles unrelated changes that can each be
planned on its own.

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
2. Explore the repo as far as the plan needs. Carry the
   project's own vocabulary into the plan — its glossary or domain-model doc
   where it has one — and respect any ADR covering the area you're touching.

   - Ask `codebase-memory-mcp`'s MCP tools before Grep/Glob/Read: its own
     skill names the verbs, and its hooks route the search either way.
   - A plan hinging on third-party API or library behavior that local code
     cannot confirm: read the entry's `**Fact:**` lines and the `facts` file
     Step 1 printed first, because an earlier invocation may already have
     answered it.
     Still open, and running in the user's own thread: hand the question to
     `/mattpocock-skills:research` naming
     `<repo root>/.claude/.radin/state/facts/<task-id>.md` as the file to write to, plan
     the parts that do not hinge on the answer meanwhile, and record what it
     reports so the next invocation reads it instead of re-researching:

     ```bash
     radin backlog append "<id>" <<'EOF'
     **Fact:** <the answer in one sentence, naming the source that owns it>
     EOF
     radin backlog set-meta "<id>" facts "<the state/facts path above>"
     ```

     The skill asks you anything: drop it, never wait on it, and name the
     question in the report. Non-interactive: name it and stop —
     `radin-execute`'s router owns the research arm
     (`lib/radin-execute-clarify.md`) and appends the answer to this task's
     file, so the next planning wave reads it.
3. Sketch the seam the change will be tested at: the highest existing one, and
   a new one only at the highest point available. Interactive: confirm it with
   the user before anything is written. Non-interactive: write on.
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
6. Insert the pointer via the CLI (adds the path to the entry, after any
   earlier plan pointer):

   ```bash
   radin backlog add-plan "<id>" "<the plan_file path>"
   ```

This skill's whole output is the plan file(s) it writes, plus the plan
pointer — and the `**Fact:**` line and `facts` pointer, when research ran —
that the CLI records against the scoped task. Nothing else in the tree
changes: no source file edited, no build or test run, no commit.

### The plan template

Write a section only when it carries content a downstream agent acts on; a
label with nothing under it goes nowhere.

<plan-template>

```markdown
# Plan: <task title>

**Task:** `<task id>` — <the `task_file` path Step 1 printed>

## Outcome

<One or two lines: what is true of the codebase once this plan is implemented.>

## Decisions

<A numbered list: every choice the executor would otherwise have to make, each
one settled here. Each entry in the format:>

1. <The question> → <the settled answer>. Why: <one line>.

<Every claim carries its source inline: `path:line` or the read-only command
that produced it for current code, the owning docs/spec/API for third-party
behavior. A claim with no source is an open question, which ends the run per
Step 3's step 4 rather than entering a plan step, and a decision the executor
has to invent is a defect in this plan.>

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

## Step 4: Review each plan on both axes

The plan is the cheapest place to correct the work. Review it on the two axes
`skills/radin-review/SKILL.md` runs over code — Standards against this repo's
rubrics, Spec against the entry — kept separate for the same reason.

Per plan file, dispatch both axes in one message as two parallel sub-agents.
Each brief names two absolute paths — the plan file, and the `task_file` Step 1
printed — and says "read both in full before reviewing". The plan file is the
whole review surface: every finding cites one section and entry inside it, and
the repo supplies context only.

Non-interactive: run both briefs inline, Standards first. A non-interactive
`radin-plan` is itself a sub-agent and cannot rely on getting a spawned agent's
result.

**Standards brief.** Invoke `/thermo-nuclear` against the plan's content, then
`/ponytail:ponytail-review` against the same content. Report every structural
issue the rubric flags in the approach, and every place the plan breaks its own
template contract — a speculative abstraction in `## Changes`, a `## Decisions`
claim carrying no source. Report findings only, each as its claim and citation.

**Spec brief.** The entry is the spec. Report (a) every acceptance criterion no
`## Changes` entry implements and no `## Testing` box checks; (b) every
`## Changes` entry no criterion asks for, and where `## Out of scope` would put
it; (c) every `**Decision:**` line the plan contradicts. Quote the entry's line
for each finding. Report findings only, each as its claim and citation.

Relay both reports under `## Standards` and `## Spec` headings before editing
anything, each axis in its own order and neither reranked against the other.

Then fix each finding by editing the plan file in place. The fix lands in the
plan, and the backlog gains nothing: `radin-review` logs findings against code
that exists, and nobody has written this code yet.

One class of finding outruns an edit — a finding that the approach itself is
wrong, or that leaves a decision for the executor to invent. Invoke
`/mattpocock-skills:grilling` over those findings, one at a time, and fold each
settled answer into the plan's `## Decisions` before starting the next one.
Non-interactive: report the finding and stop, on Step 3's step 4 bound.

## Step 5: Report back

One line per plan, with the counts from Step 4's review:

`✅ <id> planned. Plan: <path>. Review findings: <n> standards, <n> spec.`

Then:

`Next: radin-execute (or a human) can implement from the plan(s) above.`
