# tmux

Prefix is `C-y`, not the default `C-b`. Every other binding lives in `tmux.conf`.

## Plugins

TPM manages plugins in `~/.tmux/plugins/`, not the XDG default `~/.config/tmux/plugins/`.
The Claude Code hook of `tmux-agent-sidebar` looks for its binary only in
`~/.tmux/plugins/tmux-agent-sidebar/bin/`.

`tmux-agent-sidebar` tags each agent pane with `@pane_agent` and `@pane_status`, and
sends the desktop notifications. Its Claude Code side is the `tmux-agent-sidebar@hiroppy`
plugin in `.claude/settings.json`.

Status lines 0 and 1 (`status-format[0]` and `[1]`), above the window list, show one
entry per session: line 0 a dot and the session name, line 1 the branch of its active pane.
The dot sums up the session's agents: red if one waits or failed, orange if one works,
green if all are idle, grey `○` without an agent. Sessions keep the name order of
`<prefix> s`, and the focused session sits on a lighter background.
`scripts/tmux-agent-label` pads both lines to one width per session, so they align. It cuts
both labels to the client width divided by the session count. The script counts the
sessions itself: a loop nested in a format loop clobbers tmux's shared sorted list. A click
on an entry switches to that session. The sidebar pane stays off; `<prefix> e` opens it in the current
window when you need the detail.
