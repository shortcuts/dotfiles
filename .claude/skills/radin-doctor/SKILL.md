---
name: radin-doctor
description: |
  Check that radin's own install under ~/.claude is complete and its
  optional companion tools are reachable. Use for /radin-doctor, "check my
  radin install", "is radin installed correctly", "radin doctor", "verify
  radin install".
---
# Doctor

Read-only health check for radin's own install under `~/.claude`. Confirms agent/skill files `install.sh` should've copied present, checks radin's own lib shell scripts have valid syntax, reports which optional companion tools (rtk, code-review-graph, caveman, ponytail) currently reachable. Never mutates — mirrors `install.sh`'s own "advisory only" stance on companion tools.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-doctor.sh"
```

## Step 2: Report it

Print full output to user as-is — already lists every checked item with status.

Command exits non-zero: one or more expected files missing or invalid syntax. Tell user re-run `install.sh` (or `radin-update`) to fix. Missing/not-found companion tools advisory only, never failure — don't need this remediation.
