# Input half of the phone view: the pane above runs `rex attach`, which is view-only.
function rpin --description 'Type into a Rex block; used by rpick'
    set -l opt -b $argv[1]
    while read -P '> ' line
        switch $line
            case ':q'
                tmux kill-session
            case ':c'
                rex send-key $opt ctrl+c
            case ':esc'
                rex send-key $opt escape
            case ':k *'
                rex send-key $opt (string split ' ' -- $line)[2..]
            case ''
                rex send-key $opt enter
            case '*'
                rex send $opt -- $line; and rex send-key $opt enter
        end
    end
    tmux kill-session
end
