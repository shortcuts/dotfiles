---
name: radin-doctor
description: |
  Check that radin's own install under ~/.claude is complete and its
  optional companion tools are reachable. Use for /radin-doctor, "check my
  radin install", "is radin installed correctly", "radin doctor", "verify
  radin install".
---
# Doctor

A read-only health check for radin's own install under `~/.claude`. It
confirms that every agent and skill file `install.sh` copies is present,
checks that radin's own lib shell scripts have valid syntax, and reports
which optional companion tools (rtk, code-review-graph, caveman, ponytail)
are currently reachable. It never mutates anything, which mirrors
`install.sh`'s own "advisory only" stance on companion tools.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-doctor.sh"
```

## Step 2: Report it

Print the full output to the user as-is. It already lists every checked item
with its status.

A non-zero exit means one or more expected files are missing or have invalid
syntax. Tell the user to re-run `install.sh` (or `radin-update`) to fix it. A
missing companion tool is advisory only, never a failure, so it does not need
that remediation.
