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
  a plan for X before we execute it". radin-execute delegates to a planning
  sub-agent that invokes this skill, non-interactively, for any entry it
  judges too complex to implement without a plan.
---
# Plan a Backlog Entry

Turn one `BACKLOG.md` entry into one or more concrete implementation plans,
without writing any code. This runs inline in whichever context invokes it,
so any split judgment or open question surfaces in that conversation. When
the invoking context cannot reach the user (e.g. radin-execute's planning
sub-agent), the caller says so and this skill's questions resolve to their
non-destructive defaults: no split, no overwrite.

## Step 1: Resolve project namespace, locate BACKLOG_FILE

All backlog reads/writes go through the shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh` — never hand-edit `BACKLOG.md`
or compute its path yourself. Get the paths (also creates
`$NAMESPACE_DIR/state`, `plans/`, `reviews/`):

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" env
```

Read `REPO_ROOT`, `NAMESPACE_DIR`, `BACKLOG_FILE` from its output. Re-run
this line in any later Bash call before using these variables.

## Step 2: Resolve the task scope

Match the caller's scope against entries with the CLI — it prints one
`line_start<TAB>line_end<TAB>title` line per matching entry (exact title
match first, else case-insensitive substring):

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" find "<scope title/keyword>"
```

- **Exactly one match**: use it.
- **Multiple candidate matches**: list them and ask which one. Invoked
  non-interactively: don't guess — report the candidates and stop; the
  caller marks the task blocked for the user.
- **No match** (interactive callers only): this task isn't in
  `$BACKLOG_FILE` yet. Don't ask the user whether to create one — assume
  yes, and create it automatically: classify it into
  `feat`/`fix`/`chore`/`refactor` (see `skills/radin-record/SKILL.md`'s
  classification rubric), then:

  ```bash
  bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <category> "<short title>" <<'EOF'
  <as exhaustive a description as the scope given warrants — the task as
  the caller stated or clearly implied it, and why it matters if not
  already obvious.>
  EOF
  ```

  Report the new entry was created, then continue to Step 3 with it as the
  scoped entry.

  Invoked non-interactively, never create an entry: the scope always came
  from an existing one, so no match means the backlog drifted — report it
  and stop instead of writing a duplicate.
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

Re-run the CLI's `find` before reading an entry's lines — each inserted
`**Plan:**` line shifts every line below it, so stored numbers go stale as
soon as more than one plan is written this run.

For each sub-task, in order:

1. Read the entry (lines `line_start`-`line_end`). If this sub-task came
   from a split, its scope is only the one-line description recorded in
   Step 3 — plan just that part.
2. Explore the codebase as needed: current structure, affected files,
   existing patterns, constraints. If `code-review-graph` is installed and wired
   for this repo, use its MCP tools (`semantic_search_nodes`, `get_impact_radius`,
   `query_graph`) before Grep/Glob/Read — token-efficient structural context beats
   cold file scanning. When running commands, prefer `rtk`-wrapped commands if
   `command -v rtk` succeeds for token savings.
3. Invoke the `/ponytail` skill, then apply its ladder to produce the plan:
   - The minimum files to touch — no speculative scope.
   - The concrete change in each file.
   - Order of operations, where it matters.
   - How to verify the change (tests/checks to run), per the ladder's
     "lazy code without its check is unfinished" rule.
   Surface any open questions or risks the plan raised — don't silently
   resolve genuine ambiguity. Invoked interactively, interview the user
   about every open aspect of the entry until you reach a shared
   understanding: walk each branch of the decision tree, resolving
   dependent decisions one by one. Ask the questions one at a time, each
   with your recommended answer, and wait for the reply before the next —
   asking several at once is bewildering. If a *fact* can be found by
   exploring the repo (filesystem, code-review-graph, git history), look
   it up instead of asking; the *decisions* are the user's — put each one
   to them and wait. Don't finalize the plan until that shared
   understanding is confirmed: the plan you hand off must leave zero
   decisions to whoever executes it.
   Invoked non-interactively, an unresolvable question stops the planning
   run instead — report it rather than writing a plan around it.
4. Save the plan as markdown at `$NAMESPACE_DIR/plans/<sub-task-id>.md`.
5. Insert the pointer via the CLI — it locates the entry and appends
   `**Plan:** <path>` after its description (and after any earlier
   `**Plan:**` lines):

   ```bash
   bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add-plan "<entry title>" "$NAMESPACE_DIR/plans/<sub-task-id>.md"
   ```

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
