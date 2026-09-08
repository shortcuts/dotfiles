---
name: radin-show
description: |
  Print the current project's backlog to the terminal. Use for
  /radin-show, "show me the backlog", "what's in the backlog", "list backlog
  items", "print the backlog".
---
# Show Backlog

Print the current project's backlog as markdown. This skill is read-only, and
it is the only radin skill that prints the backlog. `radin-record` and
`radin-review` write to the backlog; `radin-plan` and `radin-execute` consume
it.

## Step 1: Print it

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" show
```

The CLI renders the backlog from the JSONL index plus each task's own file.
Never read those files directly. If the user narrows the scope to one
category ("show me fix items"), pass that category: `show fix`. The
categories are `feat`, `fix`, `chore`, and `refactor`. With no category, the
CLI prints the whole backlog.

The CLI resolves the per-project backlog path itself. If it errors with "no
backlog", tell the user the project has no backlog yet and point them at
`radin-record` or `radin-review` to start one. Do not create an empty file.

Print the output as-is. Do not summarize, reorder, or filter it beyond the
category scoping above.
