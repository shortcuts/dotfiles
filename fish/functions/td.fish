function td --description 'cd for tmux: create/reuse a session at given path'
    set -l dir $argv[1]
    if test -z "$dir"
        set dir (pwd)
    end
    set dir (realpath $dir)
    if not test -d "$dir"
        echo "td: no such directory: $dir" >&2
        return 1
    end

    set -l name (basename $dir | string replace -a '.' '_')

    # reuse any existing session already rooted at this path, regardless of its name
    set -l existing (tmux list-sessions -F '#{session_name}	#{session_path}' 2>/dev/null | string match -r "^.*\t\Q$dir\E\$")

    if test -n "$existing"
        set name (string split -f1 \t $existing[1])
    else if not tmux has-session -t "=$name" 2>/dev/null
        tmux new-session -d -s $name -c $dir
    end

    if set -q TMUX
        tmux switch-client -t "=$name"
    else
        tmux attach -t "=$name"
    end
end
