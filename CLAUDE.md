# CLAUDE.md

Personal dotfiles at `~/.config`, shared across a 2023 MacBook (Apple Silicon,
`/opt/homebrew`) and a 2018 Mac Mini (Intel, `/usr/local`).

## Cross-architecture rule

Every config must run on both Macs. Resolve Homebrew at runtime with `$(which brew)` or
`brew shellenv` — never a literal prefix. The fish config puts both `/usr/local/bin` and
`/opt/homebrew/bin` on `fish_user_paths`. Give any ARM-only or Intel-only binary a
fallback.

## Lite Mac mini

`./install.sh setup lite` (or `make install lite`) targets the Mac mini that runs agents. It
installs no GUI apps. `mise/config.toml` holds the lite tool set. `mise/config.mac.toml` holds
the rest, and only the full Mac loads it through the gitignored `mise/miserc.toml`. Add a
tool the mini needs to `config.toml`, any other tool to `config.mac.toml`.

`lite_headless` in `install.sh` sets the mini up as a headless box: no sleep, restart after
power loss, Spotlight off. It also installs two LaunchDaemons that run at boot with no login:
`com.shortcuts.rex-server` and `com.shortcuts.cleandisk` (daily `cleandisk --auto`, which
cleans only below 20 GiB free). Logs: `~/Library/Logs/com.shortcuts.*.log`.

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
| Terminal multiplexer (default driver), see `rex/CLAUDE.md` | `rex/init.lua` |
| Custom git workflow functions (`gco`, `gl`, `gpl`, `gps`, `gpsf`, `gsq`) | `fish/functions/g*.fish` |
| Abbreviations, git shortcuts | `fish/alias.fish` |

`mise` manages Go/Rust/Python/Java/Zig/Node. Add or update one with `mise use -g <lang>`.

## Terminal stack

Rex is the default terminal and multiplexer. Ghostty and tmux remain as a fallback until
Rex leaves beta. Make terminal changes in `rex/` first. Mirror them in `ghostty/` and
`tmux/` only when the user asks. Read `rex/CLAUDE.md` before you edit `rex/init.lua`.

## 3D printing

Write every `.scad`, `.stl`, and preview render under `STL/<project>/`, one directory per
model.
