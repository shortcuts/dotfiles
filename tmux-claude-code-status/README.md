# tmux-claude-code-status

See what every Claude Code session does from any tmux pane, window, or session.

- A colored dot after the window name in the status bar: **orange** working,
  **red** waiting on a permission prompt, **green** idle or done.
- The same state per session in the `<prefix> s` session tree.
- A desktop notification and a window bell when a session stops or needs input.
  Both stay silent when you already look at that pane.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/shortcuts/dotfiles/main/tmux-claude-code-status/install.sh | sh
```

Needs `curl`. The installer asks about each of the three features. A piped run
with no terminal answers yes to all of them. Re-run it to change your answers;
it is idempotent.

`jq` is only needed when `~/.claude/settings.json` already has hooks of its
own. Without it, the installer prints the JSON to merge by hand. macOS 15 and
later ship `jq` in `/usr/bin`.

## What it touches

| Path | Change |
|------|--------|
| `~/.claude/hooks/tmux-agent-notify.sh` | the hook script |
| `~/.claude/settings.json` | wires the hook to `UserPromptSubmit`, `PreToolUse`, `Notification`, `Stop`, `SessionEnd` |
| `~/.config/tmux/tmux-claude-code-status.conf` | generated tmux options |
| your `tmux.conf` | one `source-file` line, after it asks |

The installer reads your current `window-status-format` from the running tmux
server and appends the dot to it. Your own format survives.

Restart Claude Code after the install. Hooks load at session start.

## How it works

The hook writes the state into two tmux user options: `@agent_state` on the
session and `@agent_win_state` on the window. The tmux formats read those.

Two details the events alone get wrong:

- `PreToolUse` turns the dot back to orange the moment you approve a
  permission prompt. Without it the dot stays red for the whole tool call.
- A `Stop` whose payload still lists a running background task keeps the state
  orange. Claude fires another `Stop` when that task ends, which marks it idle.
  Credit to [tmux-agent-status](https://github.com/samleeney/tmux-agent-status)
  for that one.

Known limit: two Claude panes in one tmux session share `@agent_state`, so the
session tree shows the last event. The per-window dot is unaffected.

## Uninstall

```sh
rm ~/.claude/hooks/tmux-agent-notify.sh ~/.config/tmux/tmux-claude-code-status.conf
```

Then drop the `source-file` line from your `tmux.conf`. Remove the four hook
entries from `~/.claude/settings.json`:

```sh
jq 'del(.hooks[][] | select(.hooks[]?.command? // "" | test("tmux-agent-notify")))' \
  ~/.claude/settings.json >/tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```
