set -q TMUX; or exit 0

function __tmux_session_update
    set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
    or return

    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)

    set -l remote_url (command git remote get-url origin 2>/dev/null)
    set -l repo_name (string replace -r '.*[:/]([^/]+/[^/]+?)(?:\.git)?$' '$1' -- $remote_url)

    if test -z "$repo_name"
        set repo_name (basename $repo_root)
    end

    set -l name "$repo_name - $branch"

    test "$__tmux_cached_name" = "$name"; and return

    tmux rename-session -- "$name"
    set -g __tmux_cached_name "$name"
end

function __tmux_on_pwd_change --on-variable PWD
    __tmux_session_update
end

function __tmux_on_postexec --on-event fish_postexec
    string match -rq '^git\b' $argv[1]; and __tmux_session_update
end

__tmux_session_update
