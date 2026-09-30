#!/usr/bin/env bats
# Run: bats scripts/tmux-git-status.bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/tmux-git-status"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
        GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    git init -q -b main "$BATS_TEST_TMPDIR/origin"
    git -C "$BATS_TEST_TMPDIR/origin" commit -q --allow-empty -m base
    git clone -q "$BATS_TEST_TMPDIR/origin" "$BATS_TEST_TMPDIR/repo"
    REPO="$BATS_TEST_TMPDIR/repo"
}

# tmux style directives carry no information for the assertions.
status() { "$SCRIPT" "$1" | LC_ALL=C sed 's/#\[[^]]*\]//g'; }

@test "clean branch level with main shows only the branch" {
    git -C "$REPO" switch -q -c feat/x
    [ "$(status "$REPO")" = "repo - feat/x" ]
}

@test "counts lines added and deleted since main, uncommitted work included" {
    printf 'a\nb\nc\n' >"$BATS_TEST_TMPDIR/origin/f"
    git -C "$BATS_TEST_TMPDIR/origin" add f
    git -C "$BATS_TEST_TMPDIR/origin" commit -q -m f
    git -C "$REPO" pull -q
    git -C "$REPO" switch -q -c feat/x
    printf 'a\nx\ny\n' >"$REPO/f"
    git -C "$REPO" commit -q -am edit
    git -C "$BATS_TEST_TMPDIR/origin" commit -q --allow-empty -m upstream
    git -C "$REPO" fetch -q
    printf 'z\n' >>"$REPO/f"
    [ "$(status "$REPO")" = "repo - feat/x - +3 -2" ]
}

@test "prints nothing outside a git repo" {
    [ -z "$(status "$BATS_TEST_TMPDIR")" ]
}

@test "a worktree shows its own directory, from any subdirectory" {
    git -C "$REPO" worktree add -q -b feat/wt "$BATS_TEST_TMPDIR/repo-worktree-ai"
    mkdir "$BATS_TEST_TMPDIR/repo-worktree-ai/sub"
    [ "$(status "$BATS_TEST_TMPDIR/repo-worktree-ai/sub")" = "repo-worktree-ai - feat/wt" ]
}
