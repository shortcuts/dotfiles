# One-tap entry for the phone: list every block of every session, then open the live view.
function rpick --description 'Pick a Rex block and drive it with rp'
    set -l ids
    set -l names
    set -l sess
    for s in (rex ls | awk 'NR>1{print $1}')
        for b in (rex block ls -s $s | awk 'NR>1{print $2 "/" $4}')
            set -a ids (string split / $b)[1]
            set -a names "$s: "(string split / $b)[2]
            set -a sess $s
        end
    end
    switch (count $ids)
        case 0
            echo 'no Rex blocks'
            return 1
        case 1
            __rp_open $sess[1] $ids[1]
            return
    end
    for i in (seq (count $ids))
        echo "$i) $names[$i]"
    end
    read -P '# ' n; or return
    test -n "$ids[$n]"; and __rp_open $sess[$n] $ids[$n]
end

# tmux gives the phone a live top pane (view-only attach) and a 2-line input pane.
function __rp_open
    tmux kill-session -t phone 2>/dev/null
    tmux new-session -d -s phone "rex attach $argv[1]"
    tmux split-window -v -l 2 -t phone "fish --no-config -c 'source ~/.config/fish/functions/rpin.fish; rpin $argv[2]'"
    tmux set -t phone status off
    tmux attach -t phone
end
