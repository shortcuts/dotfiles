---
name: radin-uninstall
description: |
  Remove everything install.sh copied into ~/.claude -- radin's agent,
  skills, and lib scripts. Use for /radin-uninstall, "uninstall radin",
  "remove radin", "tear down radin", "get rid of radin".
---
# Uninstall

Removes every file `install.sh` copied into `~/.claude`: the `radin-execute`
agent, all `radin-*` skill directories (including this one), and radin's lib
scripts under `~/.claude/.radin/lib/`. It removes only the files it names
explicitly. It never wildcard-deletes `~/.claude/agents` or
`~/.claude/skills`, because the consumer's other tools live there too.

It leaves three things untouched: `thermo-nuclear` (this repo does not vendor
it), the advisory companion tools (rtk, code-review-graph, caveman, ponytail),
and any `<repo-root>/.claude/.radin/` backlog directory in the consumer's
repo. That backlog is the user's own data, so deleting it is not radin's call.

## Step 1: Run it

```bash
bash "$HOME/.claude/.radin/lib/radin-uninstall.sh"
```

## Step 2: Report it

Print the full output to the user as-is. It already lists what was removed and
what was left untouched, with manual removal commands for the advisory
companion tools.
