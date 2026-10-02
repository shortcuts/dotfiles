#!/usr/bin/env bats
# Run: bats scripts/tmux-agent-label.bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/tmux-agent-label"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
        GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    git init -q -b main "$BATS_TEST_TMPDIR/metis"
    git -C "$BATS_TEST_TMPDIR/metis" commit -q --allow-empty -m base
    # one session: its entry gets the client width minus 3
    mkdir "$BATS_TEST_TMPDIR/bin"
    # list-panes prints "window_index|window_active|@pane_agent|@pane_status" per pane
    printf '#!/bin/sh\n[ "$1" = list-panes ] && echo "$TMUX_PANES" || echo "$TMUX_SESSIONS"\n' >"$BATS_TEST_TMPDIR/bin/tmux"
    chmod +x "$BATS_TEST_TMPDIR/bin/tmux"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH" TMUX_SESSIONS='$1' TMUX_PANES='1|1||'
}

label() { "$SCRIPT" "$@" | LC_ALL=C sed 's/#\[[^]]*\]//g'; }

@test "a worktree shows the main repo name, not its directory" {
    git -C "$BATS_TEST_TMPDIR/metis" worktree add -q -b fix/x "$BATS_TEST_TMPDIR/metis-worktree-ai"
    [ "$(label "$BATS_TEST_TMPDIR/metis-worktree-ai" repo 43)" = "metis " ]
}

@test "repo and branch are padded to one width so the two lines align" {
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/longer
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 43)" = "metis       " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 43)" = "feat/longer " ]
}

# an entry adds 2 columns to its label: one pad space, one separator space
@test "a long branch is cut to fit the columns each agent gets" {
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/metishttp-buffer-request-body
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 19)" = "feat/metishtt… " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 19)" = "metis          " ]
}

@test "a long repo name is cut too" {
    git init -q -b main "$BATS_TEST_TMPDIR/infra-cli-tools"
    [ "$(label "$BATS_TEST_TMPDIR/infra-cli-tools" repo 15)" = "infra-cli… " ]
}

@test "a directory outside git shows its name and no branch" {
    mkdir "$BATS_TEST_TMPDIR/notes"
    [ "$(label "$BATS_TEST_TMPDIR/notes" repo 43)" = "notes " ]
    [ "$(label "$BATS_TEST_TMPDIR/notes" branch 43)" = "      " ]
}

@test "a session name replaces the repo and keeps the branch" {
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/longer
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 43 _config)" = "_config       " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 43 _config)" = "feat/longer ■ " ]
}

@test "the client width is shared by every session" {
    # three sessions: 51 / 3 - 3 = 14 columns, 12 for text
    export TMUX_SESSIONS='$1
$2
$3'
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/metishttp-buffer-request-body
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 51)" = "feat/metish… " ]
}

@test "a session shows one pip per window after its branch, the active one filled" {
    export TMUX_PANES='1|0||
2|1||
2|0||
3|0||'
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 43 metis)" = "main □■□ " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 43 metis)" = "metis    " ]
}

@test "the pips count toward the branch cut" {
    export TMUX_PANES='1|1||
2|0||'
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/metishttp-buffer-request-body
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 19 metis)" = "feat/metis… ■□ " ]
}

@test "a pip takes the color of its most urgent agent" {
    export TMUX_PANES='1|1||
2|0|claude|idle
3|0|claude|working
3|0|claude|idle
4|0|claude|idle
4|0|codex|waiting
5|0|claude|error'
    out=$("$SCRIPT" "$BATS_TEST_TMPDIR/metis" branch 80 metis)
    [ "${out#*main }" = "#[fg=#768390]■#[fg=#57ab5a]□#[fg=#f69d50]□#[fg=#e5534b]□#[fg=#e5534b]□ " ]
}
