---
name: radin-doctor
description: |
  Check that radin's install under ~/.claude is complete and its companion
  tools are reachable.
disable-model-invocation: true
---
# Doctor

A read-only health check for radin's own install under `~/.claude`.

```bash
radin doctor
```

Print the full output to the user as-is. It already lists every checked item
with its status.

A non-zero exit means one or more expected files are missing or have invalid
syntax. Tell the user to re-run `install.sh` (or `radin update`) to fix it.
