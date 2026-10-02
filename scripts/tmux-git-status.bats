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

@test "counts commits against upstream and lines changed since main, uncommitted work included" {
    printf 'a\nb\nc\n' >"$BATS_TEST_TMPDIR/origin/f"
    git -C "$BATS_TEST_TMPDIR/origin" add f
    git -C "$BATS_TEST_TMPDIR/origin" commit -q -m f
    git -C "$REPO" pull -q
    git -C "$REPO" switch -q -c feat/x --track origin/main
    printf 'a\nx\ny\n' >"$REPO/f"
    git -C "$REPO" commit -q -am edit
    git -C "$BATS_TEST_TMPDIR/origin" commit -q --allow-empty -m upstream
    git -C "$BATS_TEST_TMPDIR/origin" commit -q --allow-empty -m upstream
    git -C "$REPO" fetch -q
    printf 'z\n' >>"$REPO/f"
    [ "$(status "$REPO")" = "feat/x ↑1 ↓2 - +3 -2" ]
}
