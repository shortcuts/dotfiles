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

All radin state for a project lives inside that project's repo, in
`.claude/.radin/` at the repo root (example: repo `/Users/x/proj` →
`/Users/x/proj/.claude/.radin/BACKLOG.md`). Do not compute this path
yourself — run the shared namespace-resolution script and read `REPO_ROOT`,
`NAMESPACE_DIR`, `BACKLOG_FILE` from its output in the **same Bash call**
(shell state doesn't persist between separate calls):

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

## Guardrails

- Read-only — never writes to `$BACKLOG_FILE` or creates it if missing.
- No summarizing/reordering/filtering unless the user's request narrowed
  scope.

## Output

Full contents of `$BACKLOG_FILE` (or the matching `## <category>`
section(s) if scope was narrowed), printed as-is.
</content>
