# Phone-friendly pane driver: Termius cannot attach to Rex, and `rex attach` is view-only.
function rp --description 'Read and type into a Rex block over SSH'
    set -l block $argv[1]
    test -n "$block"; or set block (rex block ls | awk 'NR==2{print $2}')
    set -l opt -b $block
    while true
        clear
        rex capture $opt --trim | tail -n 30
        read -P '> ' line; or break
        switch $line
            case ':q'
                break
            case ':c'
                rex send-key $opt ctrl+c
            case ':esc'
                rex send-key $opt escape
            case ':k *'
                rex send-key $opt (string split ' ' -- $line)[2..]
            case ''
            case '*'
                rex send $opt -- $line; and rex send-key $opt enter
        end
        sleep 1
    end
end
