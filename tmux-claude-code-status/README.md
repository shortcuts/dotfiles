# tmux-claude-code-status

See what every Claude Code session does from any tmux pane, window, or session.

- A colored dot after the window name in the status bar: **orange** working,
  **red** waiting on a permission prompt, **green** idle or done.
- The same state per session in the `<prefix> s` session tree.
- A desktop notification and a window bell when a session stops or needs input.
  Both stay silent when you already look at that pane.

| Sessions | Panes |
| ------------- | ------------- |
| <img width="575" height="67" alt="Screenshot 2026-08-16 at 15 03 09" src="https://github.com/user-attachments/assets/a82a057a-f18d-4575-850e-dee472d96359" />  | <img width="249" height="41" alt="Screenshot 2026-08-16 at 15 03 19" src="https://github.com/user-attachments/assets/1d0d79b7-a1b8-4943-b8c8-3e327e7af84d" /> |

## Install

Needs `curl` and `jq`.

```sh
curl -fsSL https://raw.githubusercontent.com/shortcuts/dotfiles/main/tmux-claude-code-status/install.sh | sh
```

## What it touches

| Path | Change |
|------|--------|
| `~/.claude/hooks/tmux-agent-notify.sh` | the hook script |
| `~/.claude/settings.json` | wires the hook to `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Notification`, `Stop`, `SessionEnd` |
| `~/.config/tmux/tmux-claude-code-status.conf` | generated tmux options |
| your `tmux.conf` | one `source-file` line, after it asks |

The installer reads your current `window-status-format` from the running tmux
server and appends the dot to it. Your own format survives.

Restart Claude Code after the install. Hooks load at session start.

## How it works

The hook writes the state into two tmux user options: `@agent_state` on the
session and `@agent_win_state` on the window. The tmux formats read those.

Known limit: two Claude panes in one tmux session share `@agent_state`, so the
session tree shows the last event. The per-window dot is unaffected.

## Uninstall

```sh
rm ~/.claude/hooks/tmux-agent-notify.sh ~/.config/tmux/tmux-claude-code-status.conf
```

Then drop the `source-file` line from your `tmux.conf`. Remove the hook
entries from `~/.claude/settings.json`:

```sh
jq 'del(.hooks[][] | select(.hooks[]?.command? // "" | test("tmux-agent-notify")))' \
  ~/.claude/settings.json >/tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```
