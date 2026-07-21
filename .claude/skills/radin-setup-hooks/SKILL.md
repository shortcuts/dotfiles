---
name: radin-setup-hooks
description: Wire up per-repo hooks/MCP config for radin's companion tools (code-review-graph). Use for "set up hooks", "wire up code-review-graph", "enable the knowledge graph here", or right after install.sh in a new project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` installs companion tool *binaries* globally (rtk,
code-review-graph, caveman). It does not wire per-repo config. That config
(MCP server registration, hooks, CLAUDE.md instructions) is repo-scoped and
needs setup once per project. This skill does that setup, for the repo the
user is currently in.

## Scope

Only `code-review-graph` needs this step today. `caveman` is a Claude Code
plugin — its hooks register globally at plugin-install time, nothing
repo-scoped to do. `rtk` is a CLI with no hook/MCP wiring. If radin adds
more per-repo-wired companion tools later, extend this skill rather than
write a new one.

## Steps

1. Confirm `code-review-graph` is installed: `command -v code-review-graph`.
   If missing, tell the user to run radin's `install.sh` first (or install
   it themselves) and stop — do not install it from this skill.
2. Confirm the user is in the repo they want wired (check `git rev-parse
   --show-toplevel` and show them the path). If it doesn't look right, ask.
3. Preview first: run `code-review-graph install --platform claude-code
   --dry-run` and show the user exactly which files it will write or edit
   (typically `.mcp.json` and an append to `CLAUDE.md`/`AGENTS.md`).
4. Ask for an explicit y/n confirmation before writing anything — this
   edits files in the user's repo. State it plainly: "This will write
   `.mcp.json` and append graph-tool instructions to CLAUDE.md in `<repo
   path>`. Proceed?"
5. If yes: run `code-review-graph install --platform claude-code -y`.
6. If no: stop. Do not run any variant of the install command.

Never pass `--no-hooks` or `--no-instructions` unless the user specifically
asks to skip one — this skill's whole point is full wiring.

## Non-goals

- Don't touch global `~/.claude/` state — that's `install.sh`'s job,
  already done.
- Don't run this against a repo the user didn't ask about.
- Don't silently re-run if config already exists. `code-review-graph
  install` is safe to re-run (idempotent, per its own contract), but still
  confirm with the user first, per step 4.
