# CLAUDE.md

Personal dotfiles at `~/.config`, shared across a 2023 MacBook (Apple Silicon,
`/opt/homebrew`) and a 2018 Mac Mini (Intel, `/usr/local`).

## Cross-architecture rule

Every config must run on both Macs. Resolve Homebrew at runtime with `$(which brew)` or
`brew shellenv` — never a literal prefix. The fish config puts both `/usr/local/bin` and
`/opt/homebrew/bin` on `fish_user_paths`. Give any ARM-only or Intel-only binary a
fallback.

## Setup

Clone this repo to `~/.config`, then run `./install.sh setup`. It symlinks
`~/.claude → ~/.config/.claude`, so Claude Code skills and settings are managed here.

## Gitignore strategy

`.gitignore` is a whitelist: it ignores `*`, then un-ignores specific paths. Track a new
config file by adding explicit `!path/` and `!path/**` rules. Machine-local ignores go in
`.gitignore.local`, wired through `.gitconfig` `core.excludesFile`.

## Non-obvious paths

| What | Where |
|------|-------|
| Claude Code settings and skills | `.claude/` → symlinked from `~/.claude` |
| Custom git workflow functions (`gco`, `gl`, `gpl`, `gps`, `gpsf`, `gsq`) | `fish/functions/g*.fish` |
| Abbreviations, git shortcuts | `fish/alias.fish` |

`mise` manages Go/Rust/Python/Java/Zig/Node. Add or update one with `mise use -g <lang>`.

## 3D printing

Write every `.scad`, `.stl`, and preview render under `STL/<project>/`, one directory per
model.
