function cleandisk -d "Free disk on the agent mini: caches, tmp, stale worktree builds, toolchains, gradle. --auto: unattended safe subset"
    set -l before (df -k / | awk 'NR==2 {print $4}')
    set -l auto false
    contains -- --auto $argv; and set auto true

    if $auto
        # Caches rebuild slowly on the 8 GB mini: wipe them only when space runs short.
        if test $before -gt 20971520
            echo "skip: more than 20 GiB free"
            return
        end
        # Wiping a cache or a build directory under a running build breaks it.
        # Agents build all day, so below 5 GiB a full disk costs more than a broken build.
        if test $before -gt 5242880
            and begin
                pgrep -xq 'cargo|rustc|brew|mise|npm|pnpm|yarn|bun|uv|pip|go|make|cmake|ninja|clang|cc|ld|zig|swiftc|swift-build|xcodebuild'
                or pgrep -qf 'gradle|idf\.py'
            end
            echo "skip: a build tool is running"
            return
        end
    end

    rmgradle

    # espup reinstalls the ESP toolchain, so the 'esp' rustup entry and ~/.espressif are disposable.
    # The mini builds pgpemu with ESP-IDF's copy, so unattended runs keep it.
    if not $auto
        rm -rf ~/.espressif
        command -q rustup; and rustup toolchain list | string match -q 'esp*'; and rustup toolchain uninstall esp
    end
    rm -rf ~/.cargo/registry/cache ~/.cargo/registry/src ~/.cargo/git/checkouts

    command -q brew; and begin
        brew cleanup --prune=all -s
        brew autoremove
    end
    command -q mise; and mise prune -y
    command -q npm; and npm cache clean --force
    command -q pnpm; and pnpm store prune
    command -q yarn; and yarn cache clean
    command -q bun; and bun pm cache rm
    command -q uv; and uv cache clean
    command -q pip; and pip cache purge
    command -q go; and go clean -cache -testcache

    # Playwright browsers and other tool caches download again on demand.
    find ~/Library/Caches ~/.cache -type f -atime +7 -delete 2>/dev/null

    for gitdir in (find ~/Documents ~/.config -maxdepth 3 -name .git -type d -prune 2>/dev/null)
        set -l repo (dirname $gitdir)
        # Prune only drops registrations whose directory is gone, so live worktrees stay.
        git -C $repo worktree prune
        # Agents leave worktrees behind; their build output is the bulk. Entry 1 is the main checkout.
        set -l trees (git -C $repo worktree list --porcelain | string replace -rf '^worktree ' '')
        for tree in $trees[2..-1]
            test -z (find $tree \( -path $tree/target -o -path $tree/node_modules \) -prune -o -type f -mtime -2 -print -quit 2>/dev/null); or continue
            rm -rf $tree/target $tree/node_modules
        end
    end

    # $TMPDIR holds per-user scratch; the age filter spares files a running app still uses.
    test -n "$TMPDIR"; and find $TMPDIR -mindepth 1 -mtime +7 -delete 2>/dev/null
    find ~/Library/Logs -type f -mtime +14 -delete 2>/dev/null

    set -l after (df -k / | awk 'NR==2 {print $4}')
    printf 'freed %.1f GiB, %.1f GiB available\n' (math "($after - $before) / 1048576") (math "$after / 1048576")
end
