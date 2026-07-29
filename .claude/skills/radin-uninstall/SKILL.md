---
name: radin-uninstall
description: |
  Remove everything install.sh copied into ~/.claude -- radin's agent,
  skills, and lib scripts. Use for /radin-uninstall, "uninstall radin",
  "remove radin", "tear down radin", "get rid of radin".
---
# Uninstall

Removes every file `install.sh` copies into `~/.claude` -- the
`radin-execute` agent, all `radin-*` skill directories (including this
one), and radin's lib scripts under `~/.claude/.radin/lib/`. Only removes
files radin can prove it shipped, by exact name -- never a wildcard
delete of `~/.claude/agents` or `~/.claude/skills`, which are shared with
a consumer's other tools.

Leaves untouched: `thermo-nuclear` (not vendored by this repo), advisory
companion tools (rtk, code-review-graph, caveman, i-have-adhd, ponytail),
and any `<repo-root>/.claude/.radin/` backlog directory in a consumer
repo -- that's the user's data, not something to delete on their behalf.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-uninstall.sh"
```

## Step 2: Report it

Print the full output to the user as-is -- it already lists what was
removed and what was left untouched, with manual removal commands for
the advisory companion tools.
