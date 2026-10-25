function cleandisk -d "Free disk: caches, trash, tmp, stale toolchains, gradle, docker, mole, mac-cleanup. --auto: unattended safe subset"
    set -l before (df -k / | awk 'NR==2 {print $4}')
    set -l auto false
    contains -- --auto $argv; and set auto true

    if contains -- --dry-run $argv
        # The other steps have no preview mode, so only the third-party tools run.
        command -q mo; and mo clean --dry-run
        command -q mac-cleanup; and mac-cleanup -n
        return
    end

    if $auto
        # Caches rebuild slowly on the 8 GB mini: wipe them only when space runs short.
        if test $before -gt 20971520
            echo "skip: more than 20 GiB free"
            return
        end
        # Wiping a cache or a build directory under a running build breaks it.
        if pgrep -xq 'cargo|rustc|brew|mise|npm|pnpm|yarn|bun|uv|pip|go'; or pgrep -qf gradle
            echo "skip: a build tool is running"
            return
        end
    end

    rmgradle
    # Without a running daemon the docker commands only print errors.
    # rmdocker asks for confirmation and stops every container: never unattended.
    if not $auto; and docker info >/dev/null 2>&1
        rmdocker
    end

    # Everything below downloads again on demand.
    if $auto
        # A file trashed minutes ago may still be wanted.
        find ~/.Trash -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null
    else
        rm -rf ~/.Trash/* ~/.Trash/.[!.]*
    end
    rm -rf ~/Library/Developer/Xcode/DerivedData
    xcrun simctl delete unavailable 2>/dev/null

    # espup reinstalls the ESP toolchain, so the 'esp' rustup entry and ~/.espressif are disposable.
    # The lite mini builds pgpemu with ESP-IDF's copy, so unattended runs keep it.
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

    # Prune only drops registrations whose directory is gone, so live worktrees stay.
    for gitdir in (find ~/Documents ~/.config -maxdepth 3 -name .git -type d -prune 2>/dev/null)
        git -C (dirname $gitdir) worktree prune
    end

    # $TMPDIR holds per-user scratch; the age filter spares files a running app still uses.
    test -n "$TMPDIR"; and find $TMPDIR -mindepth 1 -mtime +7 -delete 2>/dev/null
    find ~/Library/Logs -type f -mtime +30 -delete 2>/dev/null

    # Both tools can delete beyond the paths above and may prompt: interactive runs only.
    # The lite mini installs neither.
    if not $auto
        command -q mo; and mo clean
        command -q mac-cleanup; and mac-cleanup -f
    end

    set -l after (df -k / | awk 'NR==2 {print $4}')
    printf 'freed %.1f GiB, %.1f GiB available\n' (math "($after - $before) / 1048576") (math "$after / 1048576")
end
