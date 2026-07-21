---
name: radin-plan
description: |
  Write a step-by-step implementation plan for one backlog entry, without
  touching code. Takes a task scope — a title/keyword — instead of the whole
  backlog. Judges whether the scope is broad enough to split into multiple
  independent plans, confirms any split with you directly, then writes one
  plan file per resulting sub-task, reviews it with thermo-nuclear and
  ponytail-review before handing it off, and appends a `**Plan:**` pointer
  back to the entry. Use for /radin-plan, "plan this backlog entry", "write
  a plan for X before we execute it". radin-execute also invokes this skill
  itself for any entry it judges too complex to implement without a plan.
---
# Plan a Backlog Entry

Turn one `BACKLOG.md` entry into one or more concrete implementation plans,
without writing any code. This runs inline — no sub-agent, no separate
process — so any split judgment or open question surfaces directly in this
conversation instead of being decided out of sight.

## Step 1: Resolve project namespace, locate BACKLOG_FILE

Radin never writes backlog/state files into the target repo. Run the shared
namespace-resolution script — the single source of truth for this logic,
shared by every radin agent/skill — and read `REPO_ROOT`, `NAMESPACE_DIR`,
and `BACKLOG_FILE` from its output:

```bash
bash "$HOME/.claude/radin-lib/radin-namespace.sh"
```

This creates `$NAMESPACE_DIR/state`, `$NAMESPACE_DIR/plans`, and
`$NAMESPACE_DIR/reviews`, and best-effort upserts `registry.json`. Use the
printed `REPO_ROOT` / `NAMESPACE_DIR` / `BACKLOG_FILE` values for the rest of
this session.

## Step 2: Resolve the task scope

Read `$HOME/.claude/radin-lib/radin-prioritization.md`'s "Parsing
`$BACKLOG_FILE`" section — you don't need its priority-criteria section,
since you're scoping to one entry, not ordering the whole backlog.

Match the caller's scope (a title, keyword, or paraphrase) against `### title`
entries in `$BACKLOG_FILE`:

- **Exactly one match**: use it.
- **Multiple candidate matches**: list them and ask which one.
- **No match**: this task isn't in `$BACKLOG_FILE` yet — say so, suggest
  logging it with `/radin-record` first, then stop.
- **Entry already has a `**Plan:**` line**: show the existing plan path(s)
  and ask whether to re-plan (overwrite) or stop. Stop unless re-planning is
  confirmed.

Record the entry's title, `line_start`, `line_end`, and derive a kebab-case
`parent_id` from its title.

## Step 3: Judge whether the scope should split

Invoke the `/ponytail` skill, then apply its ladder to this judgment call:
does this entry need to exist as more than one plan? Default to NOT
splitting (YAGNI) — only split if the entry genuinely bundles multiple
unrelated changes, each independently plannable.

- **Not splitting**: the sub-task list is exactly one item — the entry
  itself.
- **Splitting**: show the proposed sub-task list (short kebab-case-able
  titles with a one-line description each, covering the full scope with no
  overlap) and ask for confirmation before proceeding.
  - Confirmed as-is: use the proposed list.
  - Edited: use the edited version.
  - Rejected: fall back to the single-item list above.

## Step 4: Write each plan

Re-read `line_start`/`line_end` fresh from `$BACKLOG_FILE` before each
plan — inserting a `**Plan:**` line shifts every line below it, so this
matters as soon as more than one plan is written this run.

For each sub-task, in order:

1. Read the entry (lines `line_start`-`line_end`). If this sub-task came
   from a split, its scope is only the one-line description recorded in
   Step 3 — plan just that part.
2. Explore the codebase as needed: current structure, affected files,
   existing patterns, constraints.
3. Invoke the `/ponytail` skill, then apply its ladder to produce the plan:
   - The minimum files to touch — no speculative scope.
   - The concrete change in each file.
   - Order of operations, where it matters.
   - How to verify the change (tests/checks to run), per the ladder's
     "lazy code without its check is unfinished" rule.
   Surface any open questions or risks the plan raised — don't silently
   resolve genuine ambiguity.
4. Save the plan as markdown at `$NAMESPACE_DIR/plans/<sub-task-id>.md`.
5. Insert a `**Plan:** <path>` line into the entry in `$BACKLOG_FILE`, right
   after its description (before the next `###`/`##` heading) — after any
   `**Plan:**` lines already inserted for earlier sub-tasks this run.
6. Report: `✅ <sub-task-id> planned. Plan: <path>.`

Do NOT implement the change, run builds/tests, or commit while producing the
plan — planning and executing are separate tools, even when the same
conversation ends up doing both in sequence.

Do NOT edit any source file, run builds/tests, or create a git commit at any
point in this skill.

## Step 4.5: Review each plan before handing it off

A plan is still just a proposal — catch structural problems in it before
`radin-execute` builds on top of it, the same way a diff gets reviewed before
merge. For each plan file just written:

1. Invoke `/thermo-nuclear` against the plan file's content (not the
   codebase) — does the proposed approach itself have a spaghetti shape, a
   canonical-layer leak, an orchestration-atomicity problem, or any other
   structural issue the rubric flags?
2. Invoke `/ponytail-review` against the same plan file — does the proposed
   approach carry speculative flexibility, reinvent something the stdlib or
   an existing dependency already covers, or add a layer with only one
   caller?
3. For each finding either pass raises, edit the plan file in place to fix
   it — the plan file itself is the only artifact that needs to reflect the
   finding. Don't log anything to `$BACKLOG_FILE`; there's no separate
   review record to keep, unlike `radin-review`'s scope (a merged commit),
   this plan hasn't executed yet, so the fix belongs in the plan itself.
4. Zero findings from both passes: leave the plan file untouched.

## Step 5: Report back

```
✅ Entry planned.

| Sub-task | Plan | Review findings |
|------|------|------|
| <id> | $NAMESPACE_DIR/plans/<id>.md | <count of fixes applied to the plan, or "none"> |

Next: radin-execute (or a human) can implement from the plan(s) above.
```

Never remove or rewrite anything in `$BACKLOG_FILE` beyond inserting the
`**Plan:**` line(s) for the scoped entry.
