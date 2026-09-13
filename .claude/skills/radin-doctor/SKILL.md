---
name: radin-doctor
description: |
  Check that radin's own install under ~/.claude is complete and its
  companion tools are reachable. Use for /radin-doctor, "check my
  radin install", "is radin installed correctly", "radin doctor", "verify
  radin install".
---
# Doctor

A read-only health check for radin's own install under `~/.claude`. It
confirms that every skill and lib file `install.sh` copies is present,
checks that radin's own lib shell scripts have valid syntax, and reports
which companion tools (rtk, codebase-memory-mcp, headroom, caveman,
ponytail, mattpocock-skills) are currently reachable. It never mutates
anything: a companion install is advisory, so an unreachable one is a report,
not a failure.

## Step 1: Run it

```bash
radin doctor
```

## Step 2: Report it

Print the full output to the user as-is. It already lists every checked item
with its status.

A non-zero exit means one or more expected files are missing or have invalid
syntax. Tell the user to re-run `install.sh` (or `radin-update`) to fix it. A
missing companion tool is advisory only, never a failure, so it does not need
that remediation.
