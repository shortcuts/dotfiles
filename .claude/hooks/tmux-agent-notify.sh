#!/bin/sh
# Claude Code Notification/Stop hook: desktop toast + tmux agent state.
# Replaces the herdr agent-state integration after the move back to tmux.
set -u

# NOTIFY=0 keeps the tmux state but drops the toast and the bell.
[ -f "$HOME/.claude/hooks/tmux-agent-notify.conf" ] &&
    . "$HOME/.claude/hooks/tmux-agent-notify.conf"

event="${1:-stop}"
input=$(cat 2>/dev/null || true)

if [ "$event" = "end" ]; then
    if [ -n "${TMUX_PANE:-}" ]; then
        tmux set-option -u -t "$TMUX_PANE" @agent_state 2>/dev/null || true
        tmux set-option -uw -t "$TMUX_PANE" @agent_win_state 2>/dev/null || true
    fi
    exit 0
fi

# ponytail: sed JSON parse breaks on escaped quotes in message; jq if it matters
msg=$(printf '%s' "$input" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
tool=$(printf '%s' "$input" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# A turn that ends with a background Bash task still running is not idle.
# Claude fires another Stop once the task finishes, which then marks idle.
if [ "$event" = "stop" ]; then
    case "$input" in
        *'"background_tasks":[]'*) ;;
        *'"background_tasks":['*'"status":"running"'*) event="working" ;;
    esac
fi

# Session state for the prefix+s tree: working / stuck / idle.
# The idle-timeout Notification ("waiting for your input") is not stuck.
# ponytail: last event wins per session; per-pane states if multi-agent sessions happen
case "$event" in
    working) state="working" ;;
    stuck) state="stuck" ;;
    notification)
        case "$msg" in
            *waiting\ for\ your\ input*) state="idle" ;;
            *) state="stuck" ;;
        esac ;;
    *) state="idle" ;;
esac
if [ -n "${TMUX_PANE:-}" ]; then
    tmux set-option -t "$TMUX_PANE" @agent_state "$state" 2>/dev/null || true
    # separate window option: a session-scoped @agent_state leaks into every window's status format
    tmux set-option -w -t "$TMUX_PANE" @agent_win_state "$state" 2>/dev/null || true
fi
# Notification duplicates PermissionRequest and Stop, and its idle variant fires
# 60s late, so it only moves the dot.
case "$event" in working|start|notification) exit 0 ;; esac
[ "${NOTIFY:-1}" = "0" ] && exit 0

# Skip when the user already looks at this pane in an attached session.
if [ -n "${TMUX_PANE:-}" ]; then
    watching=$(tmux display-message -p -t "$TMUX_PANE" \
        '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}' 2>/dev/null)
    [ "$watching" = "1" ] && exit 0
fi

case "$event" in
    stuck) msg="needs permission: ${tool:-a tool}" ;;
    *) msg="done" ;;
esac

title="Claude Code · $(basename "$PWD")"
if command -v osascript >/dev/null 2>&1; then
    # argv form so quotes in the message cannot break out of the osascript string
    osascript -e 'on run argv' \
        -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
        -e 'end run' "$msg" "$title" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
    notify-send -- "$title" "$msg" >/dev/null 2>&1 || true
fi

if [ -n "${TMUX_PANE:-}" ]; then
    tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null)
    if [ -n "$tty" ]; then
        printf '\a' >"$tty" 2>/dev/null || true
    fi
fi
exit 0
