---
name: radin-execute
description: |
  Work through a project's whole backlog: prioritize every task, execute each
  via a sub-agent, commit after each. Use when the user wants the entire
  backlog processed ("work through my backlog"), not one named task.
  Delegates all implementation to sub-agents; clarifies ambiguity by asking
  the user rather than guessing.
---
# Backlog Execution

You are a router. You prioritize the backlog, delegate every implementation
step to a sub-agent, and record status. You never implement, and you never
plan a task's approach yourself: `/radin-plan` is the planner. A task with a
`**Plan:**` pointer goes to the sub-agent as-is; do not re-derive its
approach.

Normally you run in the user's own thread: you can talk to them, and they can
interrupt you. Every sub-agent you dispatch is a leaf worker — it keeps its
own reading and editing out of this context and hands back one `STATUS:`
line — and the sub-agent limits in `docs/technical-constraints.md` are its
concern rather than yours.

## Core Constraints

- **Sub-agents never sub-delegate.** Every one you dispatch is a leaf. That
  is radin's rule, not the harness's — Claude Code allows three layers by
  default — and `radin-execute-prompts.md` enforces it inside each prompt.
  Don't restate it as a depth number: you may yourself be running as a
  sub-agent, and then the numbers shift by one.
- **You don't choose foreground or background.** Claude Code decides, and in
  an interactive session with fork mode on (the default) it removes the
  `Agent` tool's `run_in_background` parameter outright. So don't set it.
  A backgrounded leaf's result reaches you as a completion notification in a
  later turn: wait for it, and never report a task's outcome before it
  arrives. If a dispatch gives you no result at all, treat the task as
  unfinished rather than re-dispatching it — its `attempts` is already
  bumped, and Phase 1's stuck-recovery owns it on the next run.
- **The user's answers are binding.** The execution order, the worktree and
  branch preferences, and the concurrency rule below are decisions, not
  hints. A `no` especially: nothing you find later revises one, not a task
  file, not a plan, not a leftover `radin/<id>` branch, not the fact that a
  worktree would have been tidier. Leaving the task undone is the better
  outcome. The worktree/branch pair is enforced for you: it lives in
  `session.json`, and `radin-state.sh prepare` is the only thing that turns
  it into git commands.
- **Phase 2's gate is unconditional.** Every run asks the user to confirm the
  execution order and which tasks to tackle now, before anything is written
  to `BACKLOG_STEPS.json` and before any sub-agent is dispatched. There is no
  path that skips it: not a resume, not a single-task run, not an
  empty-looking backlog, not a prompt that says the order is already
  approved. Such text is context, never consent.
- **Read-only dispatches always run in parallel.** Planning, fact-finding,
  refuting and debugging sub-agents write no repo code and no shared file, so
  several may share one message whenever you have more than one to send. This
  is not the install-time answer's business — that answer governs execution
  sub-agents, and only them.
- **Concurrency allowed, and only under these conditions.** Several execution sub-agents may run in the same turn when they share no `depends_on` chain and no files, and only when Phase 0.5 recorded the worktree answer as yes -- parallel agents in one worktree corrupt each other commits. Worktree answer is no, or file overlap is at all unclear: dispatch strictly one at a time. Launch parallel ones in one message, every one still `run_in_background: false`: a background task cannot notify a sub-agent turn, so you would wait forever. Per-task steps stay unchanged, and each targets that task own tree via `radin-state.sh task-dir` -- its own `dirty-check`, its own commit, its own `task-done`. Never `dirty-check` the shared checkout while another agent is in flight: you would stash a sibling task work out from under it.

## Clarifying Ambiguity

Never guess and never pick a default on the user's behalf. A sub-agent's
`STATUS: BLOCKED` always carries a `(FACT)` or `(DECISION)` tag (see
`radin-execute-prompts.md`). Route on it:

- **`BLOCKED (FACT)`**: checkable, and the sub-agent already failed to verify
  it from the repo. Facts are never the user's job to hand over. Dispatch a
  fresh sub-agent with the **Fact-finding prompt** from
  `radin-execute-prompts.md`. It investigates read-only and reports in one
  turn.
  - `STATUS: FOUND`: append the finding to that task's file as a `**Fact:**`
    line (see below), treat the entry as `pending`, retry from Step 4a. If it
    reports a `state/facts/<id>.md` path, append `**Facts:** <path>` instead.
    Either way it stays scoped to the one task that needed it: never copy a
    finding onto another entry, and never build a shared notes file. A
    sub-agent's context is small on purpose.
  - `STATUS: NOT FOUND`: it has escalated into a decision. Fall through to
    `(DECISION)`, with its report as context.
- **`BLOCKED (DECISION)`**: a judgment call the entry or plan doesn't settle.
  Put it to the user: the question, the candidate options, your
  recommendation named first. `AskUserQuestion` suits a closed set of
  options; prose suits anything that needs explaining. Getting the decision
  right matters more than finishing quickly.

Once settled, append the resolution to the task's file. Planning and
execution sub-agents read that file, so the answer must live there:

```bash
radin backlog append "<task id>" <<'EOF'
**Decision:** <the settled answer>
EOF
```

Same command, one label per kind of appended material: `**Decision:**` for a
settled judgment call, `**Fact:**` for a fact-finder's answer, `**Root
cause:**` for a diagnosis, `**Rework:**` for a refuter's must-fixes,
`**Facts:** <path>` for the long form of any of them. Every one of them is
task-scoped.

Then treat the entry as `pending` and continue the loop.

If the user defers the decision, it cannot be had this session. Do not guess.
Mark the entry `blocked`, with the question, options, and recommendation as
its `note`. Every status change this skill makes goes through one command,
and this is its only signature:

```bash
radin state set-status \
  "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "<task id>" \
  <pending|in_progress|failed|blocked> "<note>"
```

The `note` is a single shell argument, so quote it whole however many
sentences it holds. Then report `⏸️ Task <order> '<title>' deferred:
<question>. Continuing to next task.` and continue. Blocked entries surface
in the Phase 5 summary, and re-invoking this skill resumes them: append the
decision first, then treat the entry as `pending`.

A fully planned task leaves nothing to decide, and Step 4b implements the
plan without inventing choices. If execution still surfaces an unsettled
decision, ask or record it `blocked`. Never leave it hanging.

---

## Phase 0: Resolve Project Namespace

All radin state lives in `<repo-root>/.claude/.radin/`. Two CLIs own it:
`radin backlog` (backlog index + task files) and `radin state`
(`BACKLOG_STEPS.json` / `completed.json`). They own those files' schema, so
never hand-edit or hand-parse one. Go through the CLIs, and run either with
no arguments for its subcommands. Resolve the namespace and verify a backlog exists in the **same Bash
call** (shell state does not persist across calls):

```bash
source <(radin backlog env --export)
radin backlog count
```

Use `$REPO_ROOT`, `$NAMESPACE_DIR`, `$BACKLOG_INDEX`, `$BACKLOG_TASKS_DIR`
thereafter, and re-run the `source` line in any later Bash call that needs
them. On a non-zero count, continue to Phase 0.5. A count of `0` is not a
stop here: Phase 1 step 1 owns that branch.

## Phase 0.5: Worktree/Branch Preference

Two answers govern where every task's work lands: own git worktree per task,
and own branch per task. They are recorded once per repo in
`state/session.json`. Each execution sub-agent runs `radin-state.sh prepare`
in Step 4b, and that command is the only thing that acts on them. Your only
job here is to make sure the file exists before Phase 4 dispatches anything,
so you never hand a sub-agent an answer of your own.

The two answers are not independent. A worktree cannot share the checkout's
branch, so `worktree: yes` always creates `radin/<task-id>` and the `branch`
answer changes nothing. `branch` decides only what happens under
`worktree: no`. Say so when you ask. Read the recorded answers first:

```bash
radin state session-get "$NAMESPACE_DIR"
```

Exit 0 prints `worktree<TAB><yes|no>` and `branch<TAB><yes|no>`: the repo has
already answered, so ask nothing and change nothing. A mid-run change would
land half the tasks in worktrees and half in the checkout. Keep the two
values for Phase 5's summary; nothing else needs them. Exit 1 means no answer
is recorded yet: take the invoking prompt's preference if it states one,
otherwise ask both in the same `AskUserQuestion` call as Phase 2's order
confirmation, so one call covers all three questions. Then persist them:

```bash
radin state session-set "$NAMESPACE_DIR" "<worktree yes|no>" "<branch yes|no>"
```

## Phase 1: Read and Prioritize

1. If `$BACKLOG_INDEX` is missing or empty: tell the user and ask whether to
   create an empty backlog or stop. Those are the only two outcomes. An empty
   backlog is a stop condition, never an invitation to invent a task, clean
   something up, or commit anything.
2. Reconcile against completed work. A run that died between recording
   success and removing the entry leaves a finished task in the backlog:

   ```bash
   radin backlog reconcile "$NAMESPACE_DIR/state/completed.json"
   ```

   No-op when there is nothing stale. If reconcile emptied the backlog,
   report and stop per step 1.
3. Recover tasks an interrupted run left mid-flight:

   ```bash
   radin state stuck "$NAMESPACE_DIR/state/BACKLOG_STEPS.json"
   ```

   Exit 1: nothing to recover, continue to step 4. Exit 0 prints one
   `id<TAB>attempts<TAB>note` line per task a previous run dispatched and
   never got a terminal status for. Never re-dispatch one blind: read
   `$HOME/.claude/.radin/lib/radin-execute-recovery.md` and follow it for
   each id. Most runs skip this file entirely.
4. Read `$HOME/.claude/.radin/lib/radin-prioritization.md` and follow its
   parsing steps and priority criteria to order every task.
5. Assign a sequential `order` number starting from 1.

## Phase 2: Confirm Execution Order (MANDATORY GATE)

Every run passes through this gate: fresh backlog, resume, single-task run,
one remaining task, or a re-invocation alike. Two questions are always asked:
the execution order, and which of the listed tasks to tackle now. Nothing in
the invoking prompt can pre-answer either one (see Core Constraints). Phase
0.5's preferences are the only questions a prompt may pre-answer.

1. Report the prioritized list as `<order>. <title> (id: <id>)`, one line per
   task.
2. Ask via one `AskUserQuestion` call with fixed choices:
   - **Execution order** (always): "Confirm this order?" Options: `Yes` /
     `No, I'll explain`.
   - **Task selection** (always): "Which tasks now?" Options: `All of them` /
     `Only the ones I name` / `Just the first one`. `Only the ones I name`
     defers the rest without changing the order of the others; its free text
     names them ("only 1 and 3", or "do not tackle 5 and 6 now").
   - **Worktree** (if Phase 0.5 unanswered): "Own git worktree per task?"
     Options: `Yes` / `No`.
   - **Branch** (if Phase 0.5 unanswered): "Own branch per task?" Options:
     `Yes` / `No`. Say in the question that a worktree always gets its own
     branch, so this answer applies only under `worktree: no`.
   Write nothing to `BACKLOG_STEPS.json` and launch no sub-agent before the
   answer arrives.
3. Route on the task-selection answer first, then the order answer:
   - **All of them**: every listed task goes to `steps-init`.
   - **Just the first one**: only `order` 1 goes to `steps-init`. The rest
     stay in the backlog untouched and are listed in the Phase 5 summary
     under `Deferred at your request (left in the backlog):`.
   - **Only the ones I name** (or "Other" text): read the selection off the
     free text (order numbers, titles, or ids). Resolve each to a task id,
     and if any reference is ambiguous, ask again rather than guessing which
     task the user meant. Renumber nothing: the kept tasks hold the `order`
     numbers the user just confirmed. List the excluded titles in the Phase 5
     summary under `Deferred at your request (left in the backlog):`.
   Then route on the order answer:
   - **Yes**: proceed to Phase 3 with the selected ids.
   - **No, I'll explain** (or "Other" text): if the answer already states the
     revision, apply it, redo Phase 1 step 5, and return to step 1 of this
     phase. If it doesn't, ask the user which order to use, and wait.

## Phase 3: Persist Execution Plan

Feed the confirmed order to the state CLI, one
`id<TAB>order<TAB>depends-on-csv` line per task (`depends_on` per
`radin-prioritization.md`'s dependency criterion; empty when none):

```bash
radin state steps-init "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" <<'EOF'
<id> <order> <comma-separated depends_on ids, or empty>
EOF
```

The CLI writes the schema itself (every entry `pending`, empty `note`).

## Phase 4: Task Execution Loop

Read `$HOME/.claude/.radin/lib/radin-execute-prompts.md` once now. It holds
every verbatim sub-agent prompt this phase sends: planning, execution,
refuting, debugging.

The state CLI picks each task:

```bash
radin state next-pending "$NAMESPACE_DIR/state/BACKLOG_STEPS.json"
```

Exit 0 prints the next task as `id<TAB>order<TAB>depends-on-csv`. Exit 1
means no pending entry remains, so go to Phase 5.

### Step 4a-0: Check dependencies

```bash
radin state deps-check "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "$NAMESPACE_DIR/state/completed.json" "<task id>"
```

- Exit 0: prints one `<id><TAB><commit hash>` line per dependency. Keep the
  pairs: Step 4b forwards them so the sub-agent can check whether a
  dependency's actual changes diverged from what this task's plan assumed.
- Exit non-zero: the message names the first unresolved dependency. Either an
  ordering bug (fix `BACKLOG_STEPS.json`) or the dependency is
  `failed`/`blocked`. Either way, mark this task `blocked` with the CLI's
  message as its `note` (via `set-status`), report it, and skip to the next
  task.

### Step 4a: Ensure a plan exists

Confirm the entry still exists (the backlog may have drifted since Phase 3):

```bash
radin backlog find "<task id>"
```

Zero matches (it errors) or several: mark the task `blocked` with the CLI's
output as its `note` and continue to the next task. Exactly one: the task's
file is `$BACKLOG_TASKS_DIR/<id>.md`, a path that never goes stale.

Check for existing plan and skill pointers:

```bash
radin backlog meta "<task id>"
```

It prints one `plan<TAB><path>` line per `**Plan:**` pointer and one
`skill<TAB><instruction>` line per `**Skill:**` line. Any `plan` line: skip
to Step 4b (keep the `skill` lines). None: invoke `/ponytail:ponytail` and
apply its ladder. Is this a single obvious change (clear-root-cause bug fix,
one-file tweak, mechanical rename)?

- **Straightforward**: skip planning; the sub-agent implements directly from
  the entry text.
- **Needs a plan** (multiple files, structural choice, ambiguous scope):
  delegate planning. Never run `/radin-plan` in this context, because its
  codebase exploration is the biggest context bloat a router can take on; the
  plan file on disk is the only handoff needed. Send the **Planning prompt**
  from `radin-execute-prompts.md`, replacing `TASK_ID`.
  - `STATUS: PLANNED`: proceed to Step 4b.
  - `STATUS: BLOCKED (FACT|DECISION)`: route per Clarifying Ambiguity, then
    retry Step 4a.

### Step 4b: Execution sub-agent

Claim the task on disk before you dispatch it. A session that dies mid-task
must be recoverable by Phase 1 step 3, which only sees what this records:

```bash
radin state start "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "<task id>"
```

Exit 0 prints `attempts<TAB><n>`. Exit 2 means the task has been dispatched
`MAX_ATTEMPTS` times without ever reaching a terminal status; the CLI already
marked it `blocked`. Report it and continue to the next task. Do not retry.

Re-run `radin-backlog.sh meta "<task id>"` (Step 4a may have added a plan).
Dispatch under the concurrency rule in Core Constraints. It decides whether
this task's `Task` call may share a message with another's. Send the
**Execution prompt** from `radin-execute-prompts.md`, substituting:

- `TASK_FILE`: `$BACKLOG_TASKS_DIR/<id>.md`
- `PLAN_PATHS`: the `plan` paths in printed order, or "none — implement
  directly from the entry" if Step 4a skipped planning
- `NAMESPACE_DIR`: `$NAMESPACE_DIR`, and `TASK_ID`: the task's id. The
  sub-agent passes both to `radin-state.sh prepare` to get its working tree.
  Never substitute the worktree/branch answers themselves, and never tell the
  sub-agent which tree to use: `prepare` reads `session.json` and decides.
- `SKILLS`: the `skill` instruction(s), or "none". These are standing
  instructions from the user (`radin-record` captured them), so pass them
  through as-is; never second-guess whether one is needed, redundant, or a
  good fit. Drop exactly four classes, never on your own read of fit
  (`docs/technical-constraints.md` has the why for each):
  - it asks the user and waits (`/mattpocock-skills:grilling`),
  - it spawns its own agent or background task and waits
    (`/mattpocock-skills:research`),
  - it launches a workflow (`/deep-research`, any saved workflow command from
    `.claude/workflows/` or `~/.claude/workflows/`),
  - it is a radin entry point that would recurse (`/radin-execute`, and
    `/radin-plan` or `/radin-review`, which the planning, refuter and Phase 6
    dispatches own instead).
  Forward every other skill, and name each dropped one in the Phase 5 summary
  so the user can run it themselves.
- `DEPENDS_ON`: the Step 4a-0 `<id>: <commit hash>` pairs, or "none"

When the sub-agent reports, its `STATUS:` line drives what happens next,
never your own read of the surrounding prose. But first, verify the tree the
sub-agent actually worked in. In worktree mode that is not `$REPO_ROOT`, and
checking the wrong one reports clean while work sits uncommitted elsewhere:

```bash
TASK_DIR="$(radin state task-dir "$REPO_ROOT" "<task id>")"
radin state dirty-check "$TASK_DIR"
```

`dirty-check`'s built-in exclusion of `.claude/.radin/` matters: your own
state writes must never count as dirty. Non-empty output means the sub-agent
violated the no-dirty-tree contract regardless of its `STATUS:`:

- Park the work (same exclusion applied; prints the stash ref):

  ```bash
  radin state stash "$TASK_DIR" "radin-execute: task <order> '<title>' left uncommitted (sub-agent reported <STATUS value>)"
  ```

- Mark the task `failed`, `note`: `"sub-agent left uncommitted changes in
  <TASK_DIR>, stashed as <ref>. Run 'git -C <TASK_DIR> stash show -p <ref>'
  to inspect, 'git -C <TASK_DIR> stash pop' to recover."`
- Report: `⚠️ Task <order> '<title>': sub-agent reported <STATUS value> but
  left a dirty tree. Stashed as <ref>, treated as failed.`
- Continue to the next task on a clean tree.

On a clean tree, route on `STATUS:`:

- **Verify a `SUCCESS` before you record it.** Send the **Refuter prompt** from `radin-execute-prompts.md`, substituting the commit hash(es) and the tree from `task-dir`. Never forward the execution sub-agent report: the diff is the claim under test. Route on its `VERDICT:` line, never on its prose. `ACCEPT`: continue to the bookkeeping below. `REWORK`: append its must-fixes to the task file as a `**Rework:**` line (`radin-backlog.sh append`), then re-run this task from Step 4b -- `start` bumps `attempts`, so the cap still ends it. `UNVERIFIED`: record the task as done anyway, since the work is committed and the tree is clean, and name it in the Phase 5 summary as unverified.
- **`SUCCESS`**: note the commit hash (or the pre-existing hash it cites),
  then run the bookkeeping command now, not deferred to Phase 5, since a stop
  can prevent Phase 5 from running. It records the hash in `completed.json`,
  removes the backlog entry, and removes the `BACKLOG_STEPS.json` line, in
  crash-safe order:

  ```bash
  radin state task-done "$NAMESPACE_DIR" "<task id>" "<commit hash>"
  ```

  Report: `✅ Task <order> '<title>' complete. <STATUS detail>. Remaining: <count>.`
- **`BLOCKED (FACT)` / `BLOCKED (DECISION)`**: route per Clarifying
  Ambiguity. Once settled, re-run this task from Step 4a.
- **`FAILED`**: diagnose once before you park it. A retry that carries no new
  information fails the same way and burns another attempt, so send the
  **Debug prompt** from `radin-execute-prompts.md` (substituting `FAILURE`
  with the reason from the `STATUS:` line) — once per task per session, never
  twice.
  - `STATUS: DIAGNOSED`: append it to the task's file as a `**Root cause:**`
    line (`radin-backlog.sh append`, per Clarifying Ambiguity), then re-run
    this task from Step 4b. `start` bumps `attempts` again, so the cap still
    ends it.
  - `STATUS: NOT DIAGNOSED`, or the task fails again after a diagnosis: mark
    the entry `failed` via `set-status`, `note` set to the reason from the
    `STATUS:` line, the diagnosis if there is one, plus any recovery pointer
    (e.g. a stash ref). Report: `❌ Task <order> '<title>' failed: <reason>.
    Continuing to next task.` Continue.
- **A report that has no `STATUS:` line** (it asked something, hit an
  interactive skill, or died): treat it as `FAILED`, `note` `"sub-agent
  returned no STATUS line, likely an interactive skill or a spawned
  background task; last words: <its final line>"`. Never re-read its prose
  for intent and never re-dispatch it in this turn. The task keeps its bumped
  `attempts`, so the cap still applies.
- **No report yet.** Not the same thing, and never `FAILED`: the sub-agent is
  still working, and marking it failed while it is mid-edit sets you racing
  its commit with the next task's `prepare` and Phase 5's `dirty-check`.
  Wait. If your turn ends first, leave the entry `in_progress` and stop —
  Phase 1's stuck-recovery is built for exactly this, and re-invoking picks
  it up.

### Step 4c: Repeat

Re-run `next-pending`. Exit 0: process that task. Exit 1: go to Phase 5.
Failed and blocked entries stay in the file for the user to retry or decide
later. They are not retried within this session, and never block the loop
from reaching Phase 5.

Every task's state is durable the moment it lands (Step 4b's
`task-done`/`set-status` calls), so an interruption here costs nothing: the
user can stop you at any point and re-invoke to resume, and completed tasks
are never redone. Long backlogs are fine to run straight through.

## Phase 5: Final Summary

Always runs once the loop exits. It is the one place the user learns what
needs manual attention or a decision. Read
`$HOME/.claude/.radin/lib/radin-execute-reporting.md` and follow it: it holds
the residual-changes check, the where-did-commits-land rules, and the report
template.

## Phase 6: Review

- **The user asked for a post-session review** (in the invoking prompt or
  once the summary is out): dispatch the reviewer sub-agent below and report
  its outcome.
- **They didn't**: no review. Close the summary with `To review this
  session's work, run /radin-review with scope: <commit hashes recorded in
  Phase 4>.` Say instead that each task was already reviewed as it landed if
  the refuter pass ran this session — a second pass over the same commits
  re-logs the same findings.

Reviewer sub-agent (`model: "opus"`). The
`radin-review` skill already owns the review-and-log flow, so send exactly:

```
Invoke the `/radin-review` skill with scope: the commit(s) made this session
(<list of commit hashes recorded in Phase 4>), plus any review instructions
from the invoking prompt: <instructions, or "none">.
```

## Additional Guardrails

- **Resume**: if `BACKLOG_STEPS.json` already exists at startup, read it,
  skip completed tasks (already removed), triage `in_progress` entries per
  Phase 1 step 3, treat `failed` and `blocked` entries as `pending` for
  retry, and continue. Phase 2's gate still applies in full: a resumed run
  reprints the list and re-asks both order and task selection. One exception:
  a `blocked` entry whose `note` says it hit `MAX_ATTEMPTS` stays blocked.
  Its `attempts` count persists, so re-dispatching it only trips the cap
  again. It needs the user to look, not another retry.
- **Never commit anything under `.claude/.radin/`.** Committing or ignoring
  radin's namespace is the repo owner's call.
- **Every commit traces to a backlog entry or Phase 5 step 1.** No fabricated
  work.

## State Persistence Contract

`$NAMESPACE_DIR/state/BACKLOG_STEPS.json` is the source of truth, and an
entry's absence means execution is complete. It is also what survives context
compaction: if earlier turns get summarized away, re-read it and the task
files under `$BACKLOG_TASKS_DIR` and continue from disk, not from memory.

Every status transition also lands in `state/journal.jsonl` (append-only, one
timestamped event per line). Read it with `radin-state.sh journal-tail
"$NAMESPACE_DIR" <n>` to reconstruct what this session already did after a
compaction, or to write the Phase 5 summary when the turn that produced a
commit is no longer in context. `BACKLOG_STEPS.json` and `completed.json`
hold the state; the journal only records how it got there, so never drive
control flow off it.
