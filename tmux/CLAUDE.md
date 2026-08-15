# tmux

- Prefix: `C-y` (not the default `C-b`)
- Reload config: `<prefix> r`
- Session finder: `<prefix> f` (uses `scripts/tmux-session-finder`, fzf over `~/Documents` + fixed paths)
- Quick jump to dotfiles: `<prefix> C-c`
- Pane navigation: vim-style (`h/j/k/l`) after prefix

## Agent notifications

`.claude/hooks/tmux-agent-notify.sh` runs on Claude Code `Notification` and
`Stop` events (wired in `.claude/settings.json`). It sends a macOS toast and
rings the pane bell. The bell sets an orange flag on the window
(`window-status-bell-style`). The flag clears when the window gets focus.
The hook stays silent when the pane is active in an attached session.
