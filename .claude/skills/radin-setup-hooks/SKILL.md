---
name: radin-setup-hooks
description: Wire up hooks/MCP config for radin's companion tools (code-review-graph). Use for "set up hooks", "wire up code-review-graph", "enable the knowledge graph here", or right after install.sh in a new project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` installs the companion tool *binaries* globally (rtk,
code-review-graph, caveman). It wires up no hook or MCP config. This skill
does that wiring for code-review-graph, through radin's own script.

## Scope

Only `code-review-graph` needs this step today. `caveman` is a Claude Code
plugin, so its hooks register globally at plugin-install time and there is
nothing to do. `rtk` is a CLI with no hook or MCP wiring. If radin later adds
another companion tool that needs wiring, extend this skill and
`lib/radin-crg-hooks.sh` instead of writing a new one.

**Never run `code-review-graph install`.** Upstream's installer replaces the
whole `hooks` key in settings.json, destroying any hooks the user already
has. `radin crg-hooks` replicates its three writes merge-only, and skips
any entry the target already defines — an existing definition, whatever its
shape, is never redefined.

## Steps

1. Confirm the user is in the repo they want wired: run `git rev-parse
   --show-toplevel` and show the path. If it does not look right, ask.
2. Ask for explicit y/n confirmation, naming the three writes: "This adds a
   code-review-graph section to `~/.claude/CLAUDE.md`, two hooks (graph
   update on edits, graph status on session start) to
   `~/.claude/settings.json`, and an MCP server entry to `.mcp.json` in
   `<repo path>`. Anything already defined is left alone. Proceed?"
3. On yes:

   ```bash
   radin crg-hooks all
   ```

4. On no: stop, write nothing.

## Report

Print the script's output as-is: one `ADDED` or `PRESENT` line per write. It
exits non-zero without writing when `code-review-graph` is missing (point the
user at radin's `install.sh`) or when a target file holds invalid JSON (the
user must fix that file first).
