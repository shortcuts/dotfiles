---
name: radin-uninstall
description: |
  Remove everything install.sh copied into ~/.claude -- radin's agent,
  skills, and lib scripts. Use for /radin-uninstall, "uninstall radin",
  "remove radin", "tear down radin", "get rid of radin".
---
# Uninstall

Removes every file `install.sh` copied into `~/.claude`: `radin-execute` agent, all `radin-*` skill directories (including this one), radin's lib scripts under `~/.claude/.radin/lib/`. Removes only files radin proves it shipped, by exact name — never wildcard delete of `~/.claude/agents` or `~/.claude/skills`, shared with consumer's other tools.

Leaves untouched: `thermo-nuclear` (not vendored by this repo), advisory companion tools (rtk, code-review-graph, caveman, i-have-adhd, ponytail), any `<repo-root>/.claude/.radin/` backlog directory in consumer repo. That backlog user's data, not something to delete on their behalf.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-uninstall.sh"
```

## Step 2: Report it

Print full output to user as-is — already lists what removed, what left untouched, with manual removal commands for advisory companion tools.