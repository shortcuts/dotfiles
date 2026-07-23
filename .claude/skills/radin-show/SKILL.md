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

## Step 1: Resolve project namespace, locate BACKLOG_FILE

Radin never writes backlog/state files into the target repo. Run the shared
namespace-resolution script — the single source of truth for this logic,
shared by every radin agent/skill — and check/print `$BACKLOG_FILE` in the
**same Bash call**. Shell state does not persist between separate Bash tool
calls, so resolving the namespace in one call and using `$BACKLOG_FILE` in a
later one would use an empty path:

```bash
source <(bash "$HOME/.claude/radin-lib/radin-namespace.sh" | sed 's/^/export /')
test -s "$BACKLOG_FILE" && cat "$BACKLOG_FILE" || echo MISSING
```

## Step 2: Show it

Output was `MISSING`: tell the user this project has no backlog yet and
point them at `radin-record` or `radin-review` to start one. Don't create an
empty file.

Output was the file contents: print them to the user as-is — no
summarizing, reordering, or filtering. If the user's request narrowed scope
(e.g. "show me the fix items", "just the open bugs"), filter to the matching
`## <category>` section(s) instead of the whole file, but default to the
whole file when they didn't ask for a subset.
</content>
