---
name: radin-setup-hooks
description: Wire codebase-memory-mcp into this repo when install.sh could not do it globally. Use for "set up hooks", "wire up codebase-memory-mcp", "enable the knowledge graph here", or when the graph's MCP tools are missing in a project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` normally wires codebase-memory-mcp globally: it runs upstream's
own configuration (skill, three graph agents, hooks, user-scope MCP entry) and
restores whatever that write dropped. When it did that, **there is nothing for
this skill to do** — the graph works in every repo with no per-project step.

This skill is the fallback for two cases:

- `python3` was missing at install time, so `install.sh` installed the binary
  only and skipped upstream's configuration (it cannot restore the hooks that
  write drops without `python3`).
- The user ran `codebase-memory-mcp uninstall` but kept radin.

Check first: `~/.claude/.radin/manifest.json` has `"cbm_agent_config": true`
when upstream's configuration ran. Say so and stop, unless the user wants a
per-repo `.mcp.json` entry anyway.

## Scope

Only `codebase-memory-mcp` needs wiring at all. `caveman` and `ponytail` are
Claude Code plugins, so their hooks register globally at plugin-install time.
`rtk` is a CLI with no hook or MCP wiring. If radin later adds another
companion tool that needs wiring, extend this skill and
`lib/radin-cbm-hooks.sh` rather than writing a new one.

**Never run `codebase-memory-mcp install` yourself.** It writes into
`~/.claude`, and upstream #1200 makes that write replace the whole
`SessionStart` array, deleting other tools' hooks. Only
`radin cbm-config install` may run it: it snapshots first and restores
after. If the user wants the full wiring and has `python3`, run that instead of
the merge-only path below, and report its `RESTORED`/`INTACT` lines as-is.

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

Print the script's output as-is: one `ADDED` or `PRESENT` line per write. It
exits non-zero without writing when `codebase-memory-mcp` is missing (point the
user at radin's `install.sh`), when `python3` is missing (it prints the
`.mcp.json` entry to paste by hand), or when a target file holds invalid JSON
(the user must fix that file first).

Then tell the user to restart Claude Code so the MCP server loads. The graph
indexes itself on first connection (`install.sh` sets `auto_index`); if a query
reports no project, ask the agent to index it (`index_repository`).
