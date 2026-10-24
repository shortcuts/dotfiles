function cleandisk -d "Free disk: gradle, docker, mole, mac-cleanup"
    set -l before (df -k / | awk 'NR==2 {print $4}')

    if contains -- --dry-run $argv
        # rmgradle and rmdocker have no preview mode, so only the third-party tools run.
        mo clean --dry-run
        mac-cleanup -n
        return
    end

    rmgradle
    # Without a running daemon the docker commands only print errors.
    if docker info >/dev/null 2>&1
        rmdocker
    end
    mo clean
    mac-cleanup -f

    set -l after (df -k / | awk 'NR==2 {print $4}')
    printf 'freed %.1f GiB, %.1f GiB available\n' (math "($after - $before) / 1048576") (math "$after / 1048576")
end
