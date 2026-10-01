# tmux

Prefix is `C-y`, not the default `C-b`. Every other binding lives in `tmux.conf`.

## Plugins

TPM manages plugins in `~/.tmux/plugins/`, not the XDG default `~/.config/tmux/plugins/`.
The Claude Code hook of `tmux-agent-sidebar` looks for its binary only in
`~/.tmux/plugins/tmux-agent-sidebar/bin/`.

`tmux-agent-sidebar` tags each agent pane with `@pane_agent` and `@pane_status`, and
sends the desktop notifications. Its Claude Code side is the `tmux-agent-sidebar@hiroppy`
plugin in `.claude/settings.json`.

Status lines 0 and 1 (`status-format[0]` and `[1]`), above the window list, read those options and show every
agent across all sessions: line 0 a dot and the repo, line 1 the branch under it.
A session with no agent gets one grey `○` entry with its name. Sessions keep the name
order of `<prefix> s`, and the focused session sits on a lighter background.
`scripts/tmux-agent-label` pads both to one width per agent, so the columns align. It cuts
both labels to `@agent_cols`, the client width divided by the agent count, so every agent
fits on screen. A click on an
entry jumps to that pane. The sidebar pane stays off; `<prefix> e` opens it in the current
window when you need the detail.
