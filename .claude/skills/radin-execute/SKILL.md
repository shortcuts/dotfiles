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

Read `/Users/clement.vannicatte/.claude/.radin/lib/radin-run.md` in full now and follow it as this skill's body.
Re-read it after any compaction.

## No-plan rule

Pass `--plan-first` to every `task-next` call. A task with no plan then comes
back as `kind planning`: delegate planning —
unconditionally, with no judgment of the task's size or shape. Planning
happens here, one task before its own execution dispatch, so the plan is
written against the tree the previous tasks' commits already left behind, and
the plan file it leaves on disk is the whole handoff. Dispatch its prompt
like any other.

- `STATUS: PLANNED`: re-run `task-next --plan-first "<task id>"`, which now hands out the execution prompt.
- `STATUS: BLOCKED (FACT|DECISION)`: route per Clarifying Ambiguity, then
  re-run the task.
