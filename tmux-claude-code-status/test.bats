#!/usr/bin/env bats
# Which events raise a desktop toast. Run: bats test.bats

setup() {
    HOOK="$BATS_TEST_DIRNAME/../.claude/hooks/tmux-claude-code-status.sh"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s/toasts"\n' \
        "$BATS_TEST_TMPDIR" >"$BATS_TEST_TMPDIR/bin/osascript"
    chmod +x "$BATS_TEST_TMPDIR/bin/osascript"
    : >"$BATS_TEST_TMPDIR/toasts"
}

# TMUX_PANE unset so the hook skips tmux and always reaches the toast branch.
toasts() { # event json
    printf '%s' "$2" | env -u TMUX_PANE HOME="$BATS_TEST_TMPDIR" \
        PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$HOOK" "$1"
    run wc -l <"$BATS_TEST_TMPDIR/toasts"
}

@test "stop toasts" {
    toasts stop '{"background_tasks":[]}'
    [ "$output" -eq 1 ]
}

@test "stop stays silent while a background task runs" {
    toasts stop '{"background_tasks":[{"status":"running"}]}'
    [ "$output" -eq 0 ]
}

@test "permission request toasts" {
    toasts stuck '{"tool_name":"Bash"}'
    [ "$output" -eq 1 ]
}

@test "permission notification does not duplicate the permission request" {
    toasts notification '{"message":"Claude needs your permission to use Bash"}'
    [ "$output" -eq 0 ]
}

@test "idle-timeout notification does not duplicate stop" {
    toasts notification '{"message":"Claude is waiting for your input"}'
    [ "$output" -eq 0 ]
}

@test "working is silent" {
    toasts working '{}'
    [ "$output" -eq 0 ]
}

@test "start is silent" {
    toasts start '{}'
    [ "$output" -eq 0 ]
}
