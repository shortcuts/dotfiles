---
name: radin-show
description: |
  Print the current project's BACKLOG.md to the terminal. Use for
  /radin-show, "show me the backlog", "what's in the backlog", "list backlog
  items", "print BACKLOG.md".
---
# Show Backlog

Print the current project's `BACKLOG.md` as-is. Read-only — no other radin
skill/agent does this; `radin-record`/`radin-review` write to it,
`radin-plan`/`radin-execute` consume it, this just displays it.

## Step 1: Print it

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" show
```

If the user narrowed scope to one category ("show me the fix items"), pass
it: `show fix` (categories: feat/fix/chore/refactor). Default to the whole
file.

The CLI resolves the per-project backlog path itself. If it errors with
"no backlog", tell the user this project has no backlog yet and point them
at `radin-record` or `radin-review` to start one — don't create an empty
file.

## Step 2: Show it

Print the output to the user as-is — no summarizing, reordering, or
filtering beyond the category scoping above.
</content>
