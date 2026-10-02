# tmux

Prefix is `C-y`, not the default `C-b`. Every other binding lives in `tmux.conf`.

## Plugins

TPM manages plugins in `~/.tmux/plugins/`, not the XDG default `~/.config/tmux/plugins/`.
The Claude Code hook of `tmux-agent-sidebar` looks for its binary only in
`~/.tmux/plugins/tmux-agent-sidebar/bin/`.

`tmux-agent-sidebar` tags each agent pane with `@pane_agent` and `@pane_status`, and
sends the desktop notifications. Its Claude Code side is the `tmux-agent-sidebar@hiroppy`
plugin in `.claude/settings.json`.

The status bar has two lines (`status-format[0]` and `[1]`) and no window list. They show
one entry per session: line 0 the session name, line 1 the branch of its active pane and
one pip per window. The active window has a filled pip `■`, the others `□`. Each pip sums
up its window's agents: red if one waits or failed, orange if one works, green if all are
idle, grey without an agent. Sessions keep the name order of `<prefix> s`, and the focused
session sits on a lighter background. A click on an entry switches to that session.

Only the focused session reads git. Its branch also shows `scripts/tmux-git-status`:
commits ahead/behind and lines changed. Each other session shows the branch cached in its
`@branch` option, last set while it had focus.

`scripts/tmux-agent-label` draws one whole line per call. One `#()` job per session keyed
on its active pane, so a new window blanked that entry until the job first ran. The
format passes the focused session, window and pane path, so tmux reruns the job at once
when one changes. The script pads both lines to one width per session, so they align. It
shares the client width as a max-min fair share. A session that needs less than an even
share keeps its need. The long sessions split the rest and get cut to one common width.

The sidebar pane stays off; `<prefix> e` opens it in the current window when you need the
detail.
