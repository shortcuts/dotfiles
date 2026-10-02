#!/usr/bin/env bats
# Run: bats scripts/tmux-agent-label.bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/tmux-agent-label"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
        GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    M="$BATS_TEST_TMPDIR/metis"
    git init -q -b main "$M"
    git -C "$M" commit -q --allow-empty -m base
    mkdir "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/notes"
    # list-panes -a -f prints "session_name|session_id|pane_current_path|@branch|@git_at|@git_detail" per session,
    # list-panes -a "P|session_name|window_index|window_active|@pane_agent|@pane_status" per pane
    cat >"$BATS_TEST_TMPDIR/bin/tmux" <<'MOCK'
#!/bin/sh
case "$1 $2 $3" in
"list-panes -a -f") echo "$TMUX_SESSIONS" ;;
"list-panes -a -F") echo "$TMUX_PANES" ;;
*) echo "$*" >>"$TMUX_LOG" ;;
esac
MOCK
    chmod +x "$BATS_TEST_TMPDIR/bin/tmux"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH" TMUX_LOG="$BATS_TEST_TMPDIR/tmux.log" TMUX_SESSIONS="metis|\$1|$M|" TMUX_PANES='P|metis|1|1||'
}

# each entry prints as "  <text><pad>  "; | marks the entry edges so the padding shows
label() { "$SCRIPT" "$@" | LC_ALL=C sed 's/#\[bg=default\] /&|/g; s/#\[[^]]*\]//g'; }

@test "the session name and the branch pad to one width so the two lines align" {
    git -C "$M" switch -q -c feat/longer
    [ "$(label repo 80 other)" = "  metis           |" ]
    [ "$(label branch 80 other)" = "  feat/longer ■   |" ]
}

@test "the focused session shows commits and lines changed after its branch" {
    printf 'a\nb\n' >"$M/f"
    [ "$(label branch 80 metis)" = "  main ■   |" ]
    git -C "$M" add f && git -C "$M" commit -q -m f
    git -C "$M" switch -q -c feat/x
    printf 'a\nx\n' >"$M/f"
    git -C "$M" update-ref refs/remotes/origin/main main
    [ "$(label branch 80 metis)" = "  feat/x - +1 -1 ■   |" ]
    [ "$(label repo 80 metis)" = "  metis              |" ]
}

@test "an unfocused session shows its cached branch" {
    export TMUX_SESSIONS="metis|\$1|$M|feat/cached"
    [ "$(label branch 80 other)" = "  feat/cached ■   |" ]
}

@test "a window switch reuses the git result cached this status-interval" {
    export TMUX_SESSIONS="metis|\$1|$M|feat/cached|$(date +%s)| #[fg=#57ab5a]+9"
    [ "$(label branch 80 metis)" = "  feat/cached +9 ■   |" ]
}

@test "a git result older than status-interval renders at once and refreshes in the background" {
    export TMUX_SESSIONS="metis|\$1|$M|feat/cached|1| #[fg=#57ab5a]+9"
    [ "$(label branch 80 metis)" = "  feat/cached +9 ■   |" ]
    for _ in 1 2 3 4 5 6 7 8 9 10; do grep -q refresh-client "$TMUX_LOG" 2>/dev/null && break; sleep 0.2; done
    grep -q '@branch main' "$TMUX_LOG"
    grep -q refresh-client "$TMUX_LOG"
}

@test "a long branch is cut to the width of the client" {
    # 19 - 5 = 14 columns: the pip takes 2, the branch 12
    export TMUX_SESSIONS="metis|\$1|$M|feat/metishttp-buffer-request-body"
    [ "$(label branch 19 other)" = "  feat/metish… ■   |" ]
}

@test "a long session name is cut too" {
    export TMUX_SESSIONS="infra-cli-tools|\$1|$M|main" TMUX_PANES='P|infra-cli-tools|1|1||'
    [ "$(label repo 15 other)" = "  infra-cli…   |" ]
}

@test "a directory outside git shows no branch" {
    export TMUX_SESSIONS="notes|\$1|$BATS_TEST_TMPDIR/notes|" TMUX_PANES='P|notes|1|1||'
    [ "$(label branch 80 notes)" = "   ■      |" ]
}

@test "long sessions share the client width evenly" {
    # 51 - 3 * 5 = 36 columns, 12 each
    long=feat/metishttp-buffer-request-body
    export TMUX_SESSIONS="a|\$1|$M|$long
b|\$2|$M|$long
c|\$3|$M|$long" TMUX_PANES='P|a|1|1||
P|b|1|1||
P|c|1|1||'
    [ "$(label branch 51 other)" = "  feat/meti… ■   |  feat/meti… ■   |  feat/meti… ■   |" ]
}

@test "short sessions take only what they need and leave the rest to long ones" {
    # 36 columns: "a" and "b" need 2 each, so metis gets 32
    export TMUX_SESSIONS="a|\$1|$BATS_TEST_TMPDIR/notes|
b|\$2|$BATS_TEST_TMPDIR/notes|
metis|\$3|$M|feat/metishttp-buffer-request-body" TMUX_PANES='P|a|1|1||
P|b|1|1||
P|metis|1|1||'
    [ "$(label branch 51 other)" = "   ■   |   ■   |  feat/metishttp-buffer-request… ■   |" ]
}

@test "a session shows one pip per window, the active one filled" {
    export TMUX_PANES='P|metis|1|0||
P|metis|2|1||
P|metis|2|0||
P|metis|3|0||'
    [ "$(label branch 80 other)" = "  main □■□   |" ]
}

@test "a pip takes the color of its most urgent agent" {
    export TMUX_PANES='P|metis|1|1||
P|metis|2|0|claude|idle
P|metis|3|0|claude|working
P|metis|3|0|claude|idle
P|metis|4|0|claude|idle
P|metis|4|0|codex|waiting
P|metis|5|0|claude|error'
    out=$("$SCRIPT" branch 80 other)
    [ "${out#*main }" = "#[fg=#768390]■#[fg=#57ab5a]□#[fg=#f69d50]□#[fg=#e5534b]□#[fg=#e5534b]□ #[norange] #[bg=default] " ]
}

@test "the focused session gets the lighter background and every entry a click range" {
    out=$("$SCRIPT" repo 80 metis)
    [ "${out%%metis*}" = "#[bg=#2d333b]  #[range=user|\$1]#[fg=#adbac7]" ]
}
