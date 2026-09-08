---
name: radin-setup-hooks
description: Wire up per-repo hooks/MCP config for radin's companion tools (code-review-graph). Use for "set up hooks", "wire up code-review-graph", "enable the knowledge graph here", or right after install.sh in a new project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` installs the companion tool *binaries* globally (rtk,
code-review-graph, caveman). It wires up no per-repo config. That config --
MCP server registration, hooks, CLAUDE.md instructions -- is repo-scoped and
needs setup once per project. This skill does that setup for the repo the
user is currently in.

## Scope

Only `code-review-graph` needs this step today. `caveman` is a Claude Code
plugin, so its hooks register globally at plugin-install time and there is
nothing repo-scoped to do. `rtk` is a CLI with no hook or MCP wiring. If
radin later adds another companion tool that needs per-repo wiring, extend
this skill instead of writing a new one.

## Steps

1. Confirm `code-review-graph` is installed: `command -v code-review-graph`.
   If it is missing, tell the user to run radin's `install.sh` first (or
   install it themselves) and stop. Do not install it from this skill.
2. Confirm the user is in the repo they want wired. Run `git rev-parse
   --show-toplevel` and show the path. If it does not look right, ask.
3. Preview first: run `code-review-graph install --platform claude-code
   --dry-run` and show the user exactly which files it will write or edit
   (typically `.mcp.json`, plus an append to `CLAUDE.md`/`AGENTS.md`).
4. Ask for explicit y/n confirmation before writing anything, because this
   edits files in the user's repo. State it plainly: "This will write
   `.mcp.json` and append graph-tool instructions to CLAUDE.md in `<repo
   path>`. Proceed?"
5. On yes: run `code-review-graph install --platform claude-code -y`.
6. On no: stop. Do not run any variant of the install command.

Never pass `--no-hooks` or `--no-instructions` unless the user specifically
asks to skip one. Full wiring is this skill's whole point.

`code-review-graph install` is idempotent per its own contract, so existing
config is not a problem, but step 4's confirmation still applies. Touch no
global `~/.claude/` state: `install.sh` owns that.
