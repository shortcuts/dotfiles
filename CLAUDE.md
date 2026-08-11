# CLAUDE.md

## What this repo is

Personal dotfiles stored at `~/.config`, shared across two Macs:

- **2023 MacBook** — Apple Silicon (ARM, `/opt/homebrew`)
- **2018 Mac Mini** — Intel x86_64 (`/usr/local`)

Configs must stay compatible with both architectures. The fish config handles dual Homebrew paths: it adds both `/usr/local/bin` and `/opt/homebrew/bin` to `fish_user_paths`. Do not hardcode a Homebrew prefix. Use `$(which brew)` or `brew shellenv`. Avoid ARM-only or Intel-only binaries in configs without a fallback.

## Install / update

```bash
./install.sh         # update everything (brew, fisher, mise, language toolchains)
./install.sh setup   # first-time setup: installs Homebrew, changes shell to fish, creates ~/.claude symlink
```

On first-time setup, `install.sh` creates `~/.claude → ~/.config/.claude` so that Claude Code skills and settings are managed through this repo. On a new machine, clone this repo to `~/.config` first, then run `./install.sh setup`.

## Gitignore strategy

The `.gitignore` uses a whitelist approach. It ignores everything (`*`), then un-ignores specific directories and files. To track a new config file, add explicit `!path/` and `!path/**` rules — do not just remove an ignore rule. Machine-local ignores go in `.gitignore.local` (wired via `.gitconfig` `core.excludesFile`).

## Key config locations

| Tool | Path |
|------|------|
| fish shell | `fish/config.fish`, `fish/alias.fish`, `fish/functions/g*.fish` |
| Neovim | `nvim/init.lua` + `nvim/lua/` |
| tmux | `tmux/tmux.conf` |
| Ghostty | `ghostty/config` |
| AeroSpace (window manager) | `aerospace/aerospace.toml` |
| Starship prompt | `starship.toml` |
| btop | `btop/btop.conf` |
| borders | `borders/bordersrc` |
| mise (language versions) | `mise/` |
| Claude Code (settings, skills) | `.claude/` → symlinked from `~/.claude` |

## Neovim / tmux

Detailed conventions live in `nvim/CLAUDE.md` and `tmux/CLAUDE.md` (loaded lazily when working in those directories).

## Fish shell

- Abbreviations (git shortcuts, etc.) are in `fish/alias.fish`
- `fish/functions/g*.fish` — custom git workflow functions (`gco`, `gl`, `gpl`, `gps`, `gpsf`, `gsq`)

## Language toolchains

`mise` manages Go/Rust/Python/Java/Zig. The `nvm.fish` fisher plugin manages Node. Run `mise use -g <lang>` to add/update.

## 3D printing / STL work

All OpenSCAD models, STL exports, and preview renders must be scoped under `STL/` (one subdirectory per model/project, e.g. `STL/skadis-pi5-mount/`). Don't create `.scad`/`.stl` files or preview output elsewhere in the repo.
