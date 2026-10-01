#!/usr/bin/env bats
# Run: bats scripts/tmux-sidebar-fit.bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/tmux-sidebar-fit"
    # -S under $BATS_TEST_TMPDIR exceeds the socket path limit, so use -L.
    SERVER="sidebar-fit-$$-$BATS_TEST_NUMBER"
    tmux -L "$SERVER" -f /dev/null new-session -d -x 171 -y 40
    tmux -L "$SERVER" new-window -d
    export TMUX="$(tmux -L "$SERVER" display -p '#{socket_path}'),0,0"
    # Same check-then-split as the plugin's `toggle --create-only`, with a sleep that makes the race certain.
    cat >"$BATS_TEST_TMPDIR/fake-sidebar" <<'EOF'
#!/bin/sh
[ "$1" = toggle ] || exit 0
tmux list-panes -t "$3" -F '#{@pane_role}' | grep -qx sidebar && exit 0
sleep 0.3
pane=$(tmux split-window -h -d -l 26 -t "$3" -P -F '#{pane_id}' 'sleep 600')
tmux set -p -t "$pane" @pane_role sidebar
EOF
    chmod +x "$BATS_TEST_TMPDIR/fake-sidebar"
    tmux set -g @agent_sidebar_bin "$BATS_TEST_TMPDIR/fake-sidebar"
    tmux set -g @sidebar_width 26
}

teardown() { tmux kill-server; }

sidebars_per_window() {
    tmux list-panes -a -F '#{window_id} #{@pane_role}' | awk '$2 == "sidebar"' | sort | uniq -c | awk '{print $1}'
}

@test "concurrent wide runs leave one sidebar per window" {
    "$SCRIPT" 171 &
    "$SCRIPT" 171 &
    "$SCRIPT" 171 &
    wait
    [ "$(sidebars_per_window)" = "$(printf '1\n1')" ]
}

@test "a stale lock does not block the script" {
    mkdir "${TMUX%%,*}-sidebar-fit.lock"
    "$SCRIPT" 171
    [ "$(sidebars_per_window)" = "$(printf '1\n1')" ]
}

@test "a drifted sidebar is reset to @sidebar_width" {
    "$SCRIPT" 171
    pane=$(tmux list-panes -a -F '#{pane_id} #{@pane_role}' | awk '$2 == "sidebar" { print $1; exit }')
    tmux resize-pane -t "$pane" -x 60
    "$SCRIPT"
    [ "$(tmux list-panes -a -F '#{@pane_role} #{pane_width}' | awk '$1 == "sidebar" { print $2 }' | sort -u)" = 26 ]
}
