#!/usr/bin/env bats
# Run: bats scripts/tmux-agent-label.bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/tmux-agent-label"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
        GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    git init -q -b main "$BATS_TEST_TMPDIR/metis"
    git -C "$BATS_TEST_TMPDIR/metis" commit -q --allow-empty -m base
}

label() { "$SCRIPT" "$@" | LC_ALL=C sed 's/#\[[^]]*\]//g'; }

@test "a worktree shows the main repo name, not its directory" {
    git -C "$BATS_TEST_TMPDIR/metis" worktree add -q -b fix/x "$BATS_TEST_TMPDIR/metis-worktree-ai"
    [ "$(label "$BATS_TEST_TMPDIR/metis-worktree-ai" repo 40)" = "metis " ]
}

@test "repo and branch are padded to one width so the two lines align" {
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/longer
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 40)" = "metis       " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 40)" = "feat/longer " ]
}

# an entry adds 5 columns to its label: "● ", one pad space, two separator spaces
@test "a long branch is cut to fit the columns each agent gets" {
    git -C "$BATS_TEST_TMPDIR/metis" switch -q -c feat/metishttp-buffer-request-body
    [ "$(label "$BATS_TEST_TMPDIR/metis" branch 17)" = "feat/metish… " ]
    [ "$(label "$BATS_TEST_TMPDIR/metis" repo 17)" = "metis        " ]
}

@test "a long repo name is cut too" {
    git init -q -b main "$BATS_TEST_TMPDIR/infra-cli-tools"
    [ "$(label "$BATS_TEST_TMPDIR/infra-cli-tools" repo 13)" = "infra-c… " ]
}

@test "a directory outside git shows its name and no branch" {
    mkdir "$BATS_TEST_TMPDIR/notes"
    [ "$(label "$BATS_TEST_TMPDIR/notes" repo 40)" = "notes " ]
    [ "$(label "$BATS_TEST_TMPDIR/notes" branch 40)" = "      " ]
}
