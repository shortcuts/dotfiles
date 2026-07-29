---
name: radin-doctor
description: |
  Check that radin's own install under ~/.claude is complete and its
  optional companion tools are reachable. Use for /radin-doctor, "check my
  radin install", "is radin installed correctly", "radin doctor", "verify
  radin install".
---
# Doctor

Read-only health check for radin's own install under `~/.claude` --
confirms the agent/skill files `install.sh` should have copied are
present, that radin's own lib shell scripts have valid syntax, and reports
which optional companion tools (rtk, code-review-graph, caveman,
i-have-adhd, ponytail) are currently reachable. Never mutates anything --
mirrors `install.sh`'s own "advisory only" stance on companion tools.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-doctor.sh"
```

## Step 2: Report it

Print the full output to the user as-is -- it already lists every checked
item with its status.

If the command exits non-zero, one or more expected files are missing or
have invalid syntax: tell the user to re-run `install.sh` (or
`radin-update`) to fix it. Missing/not-found companion tools are advisory
only, never a failure -- they don't need this remediation.
