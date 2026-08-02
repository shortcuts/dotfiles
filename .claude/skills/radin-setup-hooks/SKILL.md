---
name: radin-setup-hooks
description: Wire up per-repo hooks/MCP config for radin's companion tools (code-review-graph). Use for "set up hooks", "wire up code-review-graph", "enable the knowledge graph here", or right after install.sh in a new project.
---
# radin: Set Up Companion-Tool Hooks

`install.sh` installs companion tool *binaries* globally (rtk, code-review-graph, caveman). No per-repo config wiring. That config — MCP server registration, hooks, CLAUDE.md instructions — repo-scoped, needs setup once per project. Skill does that setup, for repo user currently in.

## Scope

Only `code-review-graph` needs this step today. `caveman` = Claude Code plugin — hooks register globally at plugin-install time, nothing repo-scoped to do. `rtk` = CLI, no hook/MCP wiring. Radin adds more per-repo-wired companion tools later, extend this skill rather than write new one.

## Steps

1. Confirm `code-review-graph` installed: `command -v code-review-graph`. Missing: tell user run radin's `install.sh` first (or install themselves), stop — don't install it from this skill.
2. Confirm user in repo they want wired (check `git rev-parse
   --show-toplevel`, show path). Doesn't look right: ask.
3. Preview first: run `code-review-graph install --platform claude-code
   --dry-run`, show user exactly which files it will write/edit (typically `.mcp.json` and append to `CLAUDE.md`/`AGENTS.md`).
4. Ask explicit y/n confirmation before writing anything — edits files in user's repo. State plainly: "This will write `.mcp.json` and append graph-tool instructions to CLAUDE.md in `<repo
   path>`. Proceed?"
5. Yes: run `code-review-graph install --platform claude-code -y`.
6. No: stop. Don't run any variant of install command.

Never pass `--no-hooks` or `--no-instructions` unless user specifically asks skip one — skill's whole point full wiring.

## Non-goals

- Don't touch global `~/.claude/` state — that's `install.sh`'s job, already done.
- Don't run against repo user didn't ask about.
- Don't silently re-run if config already exists. `code-review-graph
  install` safe to re-run (idempotent, per own contract), but still confirm with user first, per step 4.