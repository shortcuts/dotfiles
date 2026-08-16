# tmux

- Prefix: `C-y` (not the default `C-b`)
- Reload config: `<prefix> r`
- Session finder: `<prefix> f` (uses `scripts/tmux-session-finder`, fzf over `~/Documents` + fixed paths)
- Quick jump to dotfiles: `<prefix> C-c`
- Pane navigation: vim-style (`h/j/k/l`) after prefix

## Agent notifications

`.claude/hooks/tmux-agent-notify.sh` runs on the Claude Code `SessionStart`,
`UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Notification`, `Stop`
and `SessionEnd` events (wired in
`.claude/settings.json`). It sends a macOS toast and
rings the pane bell. The bell sets an orange flag on the window
(`window-status-bell-style`). The flag clears when the window gets focus.
The hook stays silent when the pane is active in an attached session.

The hook also writes the state to two user options:

- `@agent_state` (session scope) — shown in the `<prefix> s` session tree
- `@agent_win_state` (window scope) — shown as a colored dot after the window
  name in the status bar

States: `working` (orange), `stuck` (red), `idle` (green). The `SessionEnd`
event clears both options.
