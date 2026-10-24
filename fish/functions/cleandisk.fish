function cleandisk -d "Free disk: caches, trash, tmp, stale toolchains, gradle, docker, mole, mac-cleanup"
    set -l before (df -k / | awk 'NR==2 {print $4}')

    if contains -- --dry-run $argv
        # The other steps have no preview mode, so only the third-party tools run.
        mo clean --dry-run
        mac-cleanup -n
        return
    end

    rmgradle
    # Without a running daemon the docker commands only print errors.
    if docker info >/dev/null 2>&1
        rmdocker
    end

    # Everything below downloads again on demand.
    rm -rf ~/.Trash/* ~/.Trash/.[!.]*
    rm -rf ~/Library/Developer/Xcode/DerivedData
    xcrun simctl delete unavailable 2>/dev/null

    # espup reinstalls the ESP toolchain, so the 'esp' rustup entry and ~/.espressif are disposable.
    rm -rf ~/.espressif
    command -q rustup; and rustup toolchain list | string match -q 'esp*'; and rustup toolchain uninstall esp
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

    mo clean
    mac-cleanup -f

    set -l after (df -k / | awk 'NR==2 {print $4}')
    printf 'freed %.1f GiB, %.1f GiB available\n' (math "($after - $before) / 1048576") (math "$after / 1048576")
end
