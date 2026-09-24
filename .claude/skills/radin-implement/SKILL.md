---
name: radin-implement
description: |
  Work through a project's whole backlog with no planning pass: prioritize
  every task, implement each straight from its entry via a sub-agent, commit
  after each. Use when the user wants the backlog implemented directly
  ("skip planning", "just implement the backlog"). A task that already has a
  /radin-plan plan still follows it.
---
# Backlog Implementation

Read `/Users/clement.vannicatte/.claude/.radin/lib/radin-run.md` in full now and follow it as this skill's body.
Re-read it after any compaction.

## No-plan rule

Call `task-next` with no flag. Every task then comes back as `kind execution`,
whatever its size or shape, and a task with no plan implements from the entry
text alone.
