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

You are a **router**: you prioritize the backlog, dispatch every
implementation step to a sub-agent, and record status. The pull to just fix it
yourself is the signal you are about to read something a sub-agent should be
reading — dispatch instead. Absent a dispatch, produce status, not code. You
never implement, and `/radin-plan` is the planner: a task whose entry carries
a plan pointer goes to the sub-agent as-is, its approach already settled.

Your context is the session's budget. Hold the backlog at low resolution —
ids, titles, order, exit codes — and leave every zoom to a sub-agent: a task
body, a plan file, a diff, and codebase exploration above all are what a leaf
reads and hands back as one `STATUS:` line.

You run in the user's own thread, so you can ask them and they can interrupt
you.

## Core Constraints

- **Claude Code decides foreground or background**, so send every `Task` call
  with no `run_in_background`. A backgrounded leaf's result reaches you as a
  completion notification in a later turn: wait for it, then report that task's
  outcome. A task reaches its **terminal status** only when `state task-report`
  records one on disk, so a dispatch that hands back nothing leaves it
  unfinished: its `attempts` is already bumped, and Phase 1's stuck-recovery
  owns it next run.
- **The user's answers are binding.** Carry each one forward exactly as given:
  the execution order, the worktree and branch preferences, and the
  concurrency rule below are decisions, not hints. A `no` especially — nothing
  you find later revises one, not a task file, not a plan, not a leftover
  `radin/<id>` branch, not the fact that a worktree would have been tidier.
  Leaving the task undone is the better outcome. The worktree/branch pair is enforced for you: it lives in
  `session.json`, and `radin-state.sh prepare` is the only thing that turns
  it into git commands. Never substitute either answer into a sub-agent prompt
  and never name a tree for a sub-agent: `prepare` reads `session.json` and
  decides.
- **Phase 2's gate is unconditional.** Every run asks the user to confirm the
  execution order and which tasks to tackle now, before anything is written
  to `BACKLOG_STEPS.json` and before any sub-agent is dispatched. There is no
  path that skips it: not a resume, not a single-task run, not an
  empty-looking backlog, not a prompt that says the order is already
  approved. Such text is context, never consent.
- **Read-only dispatches ship as one wave.** Planning, fact-finding and
  debugging sub-agents write no repo code and no shared file — they get no
  worktree and never call `radin-state.sh prepare`, whatever Phase 0.5
  recorded. N of them to send is N `Task` calls in one message, however large
  the wave. The bullet below governs execution sub-agents, and only them.
- **Concurrency allowed, and only under these conditions.** Several execution sub-agents may run in the same turn when they share no `depends_on` chain and no files, and only when Phase 0.5 recorded the worktree answer as yes -- parallel agents in one worktree corrupt each other commits. Worktree answer is no, or file overlap is at all unclear: dispatch strictly one at a time. Launch parallel ones in one message. Per-task steps stay unchanged, and each targets that task own tree, resolved for you by `radin-state.sh dirty-recover` -- its own dirty check, its own commit, its own `task-done`. Never check the shared checkout while another agent is in flight: you would stash a sibling task work out from under it.

## Clarifying Ambiguity

When an entry is broad, vague,
or needs refinement, invoke `/mattpocock-skills:grilling` before dispatching it,
so the sub-agent gets the user's answer instead of your guess at what the entry
meant.

A sub-agent's `STATUS: BLOCKED` routes through
`/Users/clement.vannicatte/.claude/.radin/lib/radin-execute-clarify.md`: read it and follow it — it holds
the routing for both tags, the fact-finder handoff, the research arm for a
fact that lives outside this repo, and the `backlog append` labels that put a
settled answer where planning and execution sub-agents read it.

Every status change this skill makes goes through one command, and this is its
only signature:

```bash
radin state set-status \
  "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "<task id>" \
  <pending|in_progress|failed|blocked> "<note>"
```

The `note` is a single shell argument, so quote it whole however many
sentences it holds.

---

## Phase 0: Resolve Project Namespace

`radin backlog` and `radin state` own every radin state file. Never
hand-edit one, and never parse one to decide what to do next;
`radin-execute-resume.md`'s read-only resume triage is the one exception.
Resolve the namespace and verify a backlog exists in the **same Bash
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
`state/session.json`. Your only job here is to make sure the file exists
before Phase 4 dispatches anything. Read the recorded answers first:

```bash
radin state session-get "$NAMESPACE_DIR"
```

Exit 0 prints `worktree<TAB><yes|no>` and `branch<TAB><yes|no>`: the repo has
already answered, so ask nothing and change nothing. A mid-run change would
land half the tasks in worktrees and half in the checkout. Exit 1
means no answer
is recorded yet — only the first run in a repo — so read
`/Users/clement.vannicatte/.claude/.radin/lib/radin-execute-session.md` and follow it to ask and
persist them.

## Phase 1: Read and Prioritize

1. If `$BACKLOG_INDEX` is missing or empty: tell the user and ask whether to
   create an empty backlog or stop. Those are the only two outcomes. An empty
   backlog ends the run: report it and stop.
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
   `/Users/clement.vannicatte/.claude/.radin/lib/radin-execute-recovery.md` and follow it for
   each id. Most runs skip this file entirely.
4. Ask the CLI whether a ranking pass is needed at all:

   ```bash
   radin backlog order --rank-needed
   ```

   Exit 1: every entry carries a priority. No task body read, no criteria
   pass, no dependency inference — go to Phase 2. Exit 0: it printed the ids
   whose `priority` is unset. Read
   `/Users/clement.vannicatte/.claude/.radin/lib/radin-prioritization.md` and apply its weighted
   criteria to those ids alone. It produces two things: the unset group in
   your order, as one `--rank <csv-of-ids>` flag, and one
   `--infer-deps <id>=<csv>` flag per entry you inferred a dependency for.
   Carry those flags into every later `order` call this session; carry
   nothing else.

## Phase 2: Confirm Execution Order (MANDATORY GATE)

The gate is unconditional (Core Constraints). Phase 0.5's preferences are the
only questions a prompt may pre-answer.

1. Print this verbatim, and compose nothing of your own:

   ```bash
   radin backlog order --report <Phase 1's --rank/--infer-deps flags>
   ```

   One `<order>. <title> (id: <id>)` line per task in final order, then one
   `dependency override:` line per dependency the fix moved up. The verb is
   idempotent, so re-run it here rather than reusing Phase 1's output.
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
3. The two answers are routed independently, and each is routed once.
   - **Task selection** decides Phase 3's `--defer` value, and nothing else:
     - **All of them**: no `--defer` flag.
     - **Just the first one**: `--defer` every id but `order` 1's.
     - **Only the ones I name** (or "Other" text): read the selection off the
       free text (order numbers, titles, or ids). Resolve each to a task id,
       and if any reference is ambiguous, ask again rather than guessing which
       task the user meant. `--defer` the ids the user did not name.
   - **Execution order**:
     - **Yes**: proceed to Phase 3 with the selected ids.
     - **No, I'll explain** (or "Other" text): if the answer already states
       the revision, re-run `order --report` with the revised flags, print it,
       and ask the order question **alone** — one `AskUserQuestion` carrying
       that one question. If the answer does not state the revision, ask which
       order to use, and wait. Either way the task selection just given
       stands, as the ids it already resolved to: it is never re-asked, and
       never re-resolved against the revised order.

## Phase 3: Persist Execution Plan

The confirmed order is persisted by exactly this pipe:

```bash
radin backlog order --steps <Phase 1's flags> --defer "<ids Phase 2 excluded>" |
  radin state steps-init "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "$BACKLOG_INDEX"
```

`--defer` takes the ids Phase 2 excluded; omit the flag entirely when nothing
is deferred. Resolving that free text to ids is yours;
filtering, renumbering and the `depends_on` precedence are not — every listed
task keeps the `order` number the user just confirmed.

## Phase 4: Task Execution Loop

`radin state task-next` computes the **frontier** — the pending, unblocked
tasks — and hands you the first of them. The frontier is the CLI's to compute,
never yours:

```bash
radin state task-next "$NAMESPACE_DIR"
```

Exit 1 means nothing is left to run, so go to Phase 5. Exit 0 prints, in
order:

- zero or more `blocked<TAB><id><TAB><why>` lines — tasks it skipped because
  a dependency is unresolved. It already marked each one `blocked` with that
  note; report each as skipped.
- `id<TAB><id>` and `order<TAB><n>` for the task to run now.
- zero or more `dep<TAB><id><TAB><commit hash>` lines. Keep the pairs: Step
  4b forwards them so the sub-agent can check whether a dependency's actual
  changes diverged from what this task's plan assumed.

### Step 4a: Ensure a plan exists

Two calls, each answering one question:

```bash
radin backlog field "<task id>" TASK_FILE
radin backlog field "<task id>" PLAN_PATHS
```

`TASK_FILE` resolves the entry, so a non-zero exit is the drift case (the
backlog may have moved since Phase 3): mark the task `blocked` with that
call's output as its `note` and continue to the next task.

`PLAN_PATHS` exit 0: a plan exists — `/radin-plan` wrote it, or an earlier
Step 4a did — so skip to Step 4b. Exit 1: no plan, so delegate planning —
unconditionally, with no judgment of the task's size or shape. Planning
happens here, one task before its own execution dispatch, so the plan is
written against the tree the previous tasks' commits already left behind, and
the plan file it leaves on disk is the whole handoff:

```bash
radin prompt planning "<task id>"
```

It prints `model<TAB><name>`, a `--- prompt ---` line, then the prompt. Send
everything after that line as one `Task` call with exactly that model.
Substitute nothing and add nothing: the CLI assembled it.

- `STATUS: PLANNED`: proceed to Step 4b.
- `STATUS: BLOCKED (FACT|DECISION)`: route per Clarifying Ambiguity, then
  retry Step 4a.

### Step 4b: Execution sub-agent

**Claim** the task first, before any work: a pending entry with no
`in_progress` record is unclaimed, and Phase 1 step 3's stuck-recovery sees
only what this call records:

```bash
radin state start "$NAMESPACE_DIR/state/BACKLOG_STEPS.json" "<task id>"
```

Exit 0 prints `attempts<TAB><n>`. Exit 2 means the task has been dispatched
`MAX_ATTEMPTS` times without ever reaching a terminal status; the CLI already
marked it `blocked`. Report it and continue to the next task. Do not retry.

Then take the prompt from the CLI, and dispatch it under the concurrency rule
in Core Constraints — it decides whether this task's `Task` call may share a
message with another's:

```bash
radin prompt execution "<task id>"
radin backlog field "<task id>" SKILLS_DROPPED
```

`prompt` prints `model<TAB><name>`, a `--- prompt ---` line, then the prompt:
send everything after that line verbatim, with that model. It resolved the
task's text, plan, skills, acceptance criteria, dependency commits and
category itself, and left out every step this task has no input for — so your
own read of the task's shape never enters the prompt, and there is no
placeholder to substitute. `SKILLS_DROPPED` exit 0 prints the standing
instructions the CLI filtered out as unrunnable by a leaf; name each in the
Phase 5 summary so the user can run it themselves. Exit 1 — the common case —
means none were dropped.

When the sub-agent reports, hand its last line to one call. It verifies the
tree first (a dirty tree fails the task, whatever the `STATUS:` claimed), then
records the terminal state and prints the report line:

```bash
radin state task-report "$NAMESPACE_DIR" "<task id>" "<the sub-agent's STATUS: line>"
```

Two dispatches hand back no such line. A last line that is not a `STATUS:`
line — it asked something, hit an interactive skill, or died mid-turn — goes
in as `--no-status "<its final line>"` instead. A sub-agent with no content at
all is still working, whatever the elapsed time suggests: wait, and if your
turn ends first, leave the entry `in_progress` for Phase 1's stuck-recovery.

Print what the call printed, then route on its final `next` line and nothing
else:

| `next` | Do |
| --- | --- |
| `continue` | Recorded on disk. Go to Step 4c. |
| `debug` | This task still has its one debug pass. Dispatch `radin prompt debug "<task id>" "<the reason from the STATUS: line>"`. `STATUS: DIAGNOSED`: record it, then re-run this task from Step 4b — `start` bumps `attempts`, so the cap still ends it. `STATUS: NOT DIAGNOSED`: re-run `task-report` with the same line, which routes to `continue` this time. |
| `clarify FACT` / `clarify DECISION` | Route per Clarifying Ambiguity. Once settled, re-run this task from Step 4a. |

```bash
radin state task-diagnosis "$NAMESPACE_DIR" "<task id>" <<'EOF'
<the diagnosis>
EOF
```

Never verify a `SUCCESS` yourself: no verification sub-agent, and no
re-reading the diff — that read is the cost Phase 6's `/radin-review` pass
exists to avoid. A task is finished when `task-report` has recorded it,
whatever the sub-agent's prose said.

### Step 4c: Repeat

Re-run `task-next` for the next frontier task. Exit 0: process that task.
Exit 1: go to Phase 5.
Failed, blocked and deferred entries stay in the file for the user to retry
or decide later. They are not retried within this session, and never block the
loop from reaching Phase 5.

## Phase 5: Final Summary

Always runs once the loop exits, and the CLI prints it whole:

```bash
radin state report "$NAMESPACE_DIR" "<one dropped-skill line per skill Step 4b dropped>"
```

Print its output verbatim. Read
`/Users/clement.vannicatte/.claude/.radin/lib/radin-execute-reporting.md` for the two things it
cannot do.

## Phase 6: Review

- **The user asked for a post-session review** (in the invoking prompt or
  once the summary is out): dispatch the reviewer sub-agent below and report
  its outcome.
- **They didn't**: no review. Close the summary with `To review this
  session's work, run /radin-review with scope: <commit hashes recorded in
  Phase 4>.`

Reviewer sub-agent (`model: "opus"`). The
`radin-review` skill already owns the review-and-log flow, so send exactly:

```
You run non-interactively: you cannot reach the user and have no
`AskUserQuestion`, so take each non-destructive branch the skill names.

Invoke the `/radin-review` skill with scope: the commit(s) made this session
(<list of commit hashes recorded in Phase 4>), plus any review instructions
from the invoking prompt: <instructions, or "none">.
```

## Additional Guardrails

- **Resume, and recovery after a compaction**: `BACKLOG_STEPS.json` already
  exists at startup, or earlier turns got summarized away. Either way, read
  `/Users/clement.vannicatte/.claude/.radin/lib/radin-execute-resume.md` and follow it: it holds
  the resume triage, the `MAX_ATTEMPTS` exception, and the state-persistence
  contract that lets you continue from disk rather than memory. A run that
  starts clean and stays in context never loads it.
- **Leave `.claude/.radin/` out of every commit.** Whether to commit or
  ignore radin's namespace is the repo owner's call.
- **Every commit traces to a backlog entry.**
