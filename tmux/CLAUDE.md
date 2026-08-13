# tmux

- Prefix: `C-y` (not the default `C-b`)
- Reload config: `<prefix> r`
- Session finder: `<prefix> f` (uses `scripts/tmux-session-finder`, fzf over `~/Documents` + fixed paths)
- Quick jump to dotfiles: `<prefix> C-c`
- Pane navigation: vim-style (`h/j/k/l`) after prefix

## herdr

`herdr/config.toml` mirrors this file's prefix, vim pane nav, and split keys.
Herdr has no equivalent for the session-finder script or discrete `-`/`=`
resize keys. `resize_mode` is left unbound here (its default key, `r`,
went to `reload_config` to match tmux). Use herdr's built-in workspace
picker (`<prefix> w`) for session switching instead.

Fish auto-attaches the named persistent session `home` on shell start
(`fish/config.fish`), replacing tmux's old auto-attach. tmux itself is
untouched and still launches manually (`tmux attach` / `tmux new`).

`home` ships with one workspace per project, seeded once via
`herdr --session home workspace create --cwd <path>`:
`~/.config`, `~/Documents/locationjoystick`, `~/Documents/renovAIte`,
`~/Documents/pgpemu`, `~/Documents/no-neck-pain.nvim`, `~/Documents/rpi`,
`~/Documents/radin`. Workspaces persist in the session's saved state
(`herdr/sessions/home/`, untracked) — adding a new default project means
running that command again by hand, there's no declarative list in
`config.toml`.
