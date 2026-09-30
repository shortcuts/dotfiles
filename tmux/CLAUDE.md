# tmux

Prefix is `C-y`, not the default `C-b`. Every other binding lives in `tmux.conf`.

## Plugins

TPM manages plugins in `~/.tmux/plugins/`, not the XDG default `~/.config/tmux/plugins/`.
The Claude Code hook of `tmux-agent-sidebar` looks for its binary only in
`~/.tmux/plugins/tmux-agent-sidebar/bin/`.

`tmux-agent-sidebar` shows every Claude Code pane across sessions, with its state, and
sends the desktop notifications. `<prefix> e` toggles it in the current window,
`<prefix> E` in every window. Its Claude Code side is the `tmux-agent-sidebar@hiroppy`
plugin in `.claude/settings.json`.

`scripts/tmux-sidebar-fit` replaces the plugin's auto-create. On attach, resize, and every
new window or session, it opens the sidebar in every window when the client is at least
120 columns wide. On a narrower client (a phone), it closes every sidebar.
