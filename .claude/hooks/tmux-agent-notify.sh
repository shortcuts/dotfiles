#!/bin/sh
# Claude Code Notification/Stop hook: macOS toast + tmux bell flag.
# Replaces the herdr agent-state integration after the move back to tmux.
set -u

event="${1:-stop}"
input=$(cat 2>/dev/null || true)

if [ "$event" = "end" ]; then
    if [ -n "${TMUX_PANE:-}" ]; then
        tmux set-option -u -t "$TMUX_PANE" @agent_state 2>/dev/null || true
    fi
    exit 0
fi

# ponytail: sed JSON parse breaks on escaped quotes in message; jq if it matters
msg=$(printf '%s' "$input" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# Session state for the prefix+s tree: working / stuck / idle.
# The idle-timeout Notification ("waiting for your input") is not stuck.
# ponytail: last event wins per session; per-pane states if multi-agent sessions happen
case "$event" in
    working) state="working" ;;
    notification)
        case "$msg" in
            *waiting\ for\ your\ input*) state="idle" ;;
            *) state="stuck" ;;
        esac ;;
    *) state="idle" ;;
esac
if [ -n "${TMUX_PANE:-}" ]; then
    tmux set-option -t "$TMUX_PANE" @agent_state "$state" 2>/dev/null || true
fi
[ "$event" = "working" ] && exit 0

# Skip when the user already looks at this pane in an attached session.
if [ -n "${TMUX_PANE:-}" ]; then
    watching=$(tmux display-message -p -t "$TMUX_PANE" \
        '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}' 2>/dev/null)
    [ "$watching" = "1" ] && exit 0
fi

if [ "$event" = "notification" ]; then
    [ -n "$msg" ] || msg="needs attention"
else
    msg="done"
fi

title="Claude Code · $(basename "$PWD")"
# argv form so quotes in the message cannot break out of the osascript string
osascript -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
    -e 'end run' "$msg" "$title" >/dev/null 2>&1 || true

if [ -n "${TMUX_PANE:-}" ]; then
    tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null)
    if [ -n "$tty" ]; then
        printf '\a' >"$tty" 2>/dev/null || true
    fi
fi
exit 0
