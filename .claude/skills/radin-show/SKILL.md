---
name: radin-show
description: |
  Print the current project's backlog to the terminal. Use for
  /radin-show, "show me the backlog", "what's in the backlog", "list backlog
  items", "print the backlog".
---
# Show Backlog

Print current project backlog as markdown. Read-only — no other
radin skill/agent do this. `radin-record`/`radin-review` write to it.
`radin-plan`/`radin-execute` consume it. This just display it.

## Step 1: Print it

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" show
```

CLI render it from JSONL index plus each task's own file — never read those directly. User narrow scope to one category ("show me fix items"), pass it: `show fix` (categories: feat/fix/chore/refactor). Default: whole backlog.

CLI resolve per-project backlog path itself. Errors "no backlog": tell user project has no backlog yet, point at `radin-record` or `radin-review` to start one — don't create empty file.

Print output as-is — no summarize, reorder, filter beyond category scoping above.
