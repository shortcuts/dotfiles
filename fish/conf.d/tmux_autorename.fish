set -q TMUX; or exit 0

function __tmux_session_update
    # One git exec, not three: every exec costs ~25ms under Falcon's scanner
    set -l info (command git rev-parse --show-toplevel HEAD --abbrev-ref HEAD 2>/dev/null)
    or return

    set -l repo_root $info[1]
    set -l branch $info[3]
    test "$branch" = HEAD; and set branch (string sub -l 7 $info[2])

    # The remote never changes while the repo stays the same; skip its exec
    if test "$__tmux_cached_root" != "$repo_root"
        set -l remote_url (command git remote get-url origin 2>/dev/null)
        set -g __tmux_cached_repo (string replace -r '.*[:/]([^/]+/[^/]+?)(?:\.git)?$' '$1' -- $remote_url)
        test -z "$__tmux_cached_repo"; and set -g __tmux_cached_repo (basename $repo_root)
        set -g __tmux_cached_root $repo_root
    end

    set -l name "$__tmux_cached_repo - $branch"

    test "$__tmux_cached_name" = "$name"; and return

    tmux rename-session -- "$name" 2>/dev/null
    set -g __tmux_cached_name "$name"
end

# Arm hooks at first prompt: startup scripts (gcloud, mise) cd around and
# would fire the git lookups several times before the shell is usable
function __tmux_arm --on-event fish_prompt
    functions -e __tmux_arm

    function __tmux_on_pwd_change --on-variable PWD
        __tmux_session_update
    end

    function __tmux_on_postexec --on-event fish_postexec
        string match -rq '^git\b' $argv[1]; and __tmux_session_update
    end

    __tmux_session_update
end
