---
name: radin-setup-hooks
description: Wire codebase-memory-mcp into this repo when install.sh could not do it globally. Use for "set up hooks", "wire up codebase-memory-mcp", "enable the knowledge graph here", or when the graph's MCP tools are missing in a project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` normally wires codebase-memory-mcp globally: it runs upstream's
own configuration and restores whatever that write dropped. When it did that, **there is nothing for
this skill to do** — the graph works in every repo with no per-project step.

This skill is the fallback for two cases:

- A C compiler was missing at install time, so `radin-cbm-json` was never built
  and `install.sh` installed the binary only.
- The user ran `codebase-memory-mcp uninstall` but kept radin.

Check first with `radin doctor` and read its
`codebase-memory-mcp wiring (informational)` section. Both lines `OK` means
upstream's configuration already landed: say so and stop, unless the user
wants a per-repo `.mcp.json` entry anyway.

## Scope

Only `codebase-memory-mcp` needs wiring. `caveman` and `ponytail` register
their hooks globally at plugin-install time, and `rtk` is a CLI with no hook
or MCP wiring.

**Never run `codebase-memory-mcp install` yourself.** Its write replaces whole
hook arrays in `~/.claude`, deleting other tools' hooks. Only
`radin cbm-config install` may run it, because it snapshots first and
restores after. When the user wants the full wiring, run that and report its
`RESTORED`/`INTACT` lines as-is; it exits non-zero naming
`radin cbm-hooks all` as the fallback when it cannot. Otherwise use the
merge-only path below.

## Steps

1. Confirm the user is in the repo they want wired: run `git rev-parse
   --show-toplevel` and show the path. If it does not look right, ask.
2. Ask for explicit y/n confirmation, naming the two writes: "This adds a
   codebase-memory-mcp section to `~/.claude/CLAUDE.md` and an MCP server
   entry to `.mcp.json` in `<repo path>`. Anything already defined is left
   alone. Proceed?"
3. On yes:

   ```bash
   radin cbm-hooks all
   ```

4. On no: stop, write nothing.

## Report

Print the script's output as-is: one `ADDED` or `PRESENT` line per write. A
non-zero exit writes nothing and prints its own cause and remedy -- relay that
line, add nothing to it.

Then tell the user to restart Claude Code so the MCP server loads. The graph
indexes itself on first connection (`install.sh` sets `auto_index`); if a query
reports no project, ask the agent to index the project.
