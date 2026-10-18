# One-tap entry for the phone: list every block of every session, then hand off to rp.
function rpick --description 'Pick a Rex block and drive it with rp'
    set -l ids
    set -l names
    for s in (rex ls | awk 'NR>1{print $1}')
        for b in (rex block ls -s $s | awk 'NR>1{print $2 "/" $4}')
            set -a ids (string split / $b)[1]
            set -a names "$s: "(string split / $b)[2]
        end
    end
    switch (count $ids)
        case 0
            echo 'no Rex blocks'
            return 1
        case 1
            rp $ids[1]
            return
    end
    for i in (seq (count $ids))
        echo "$i) $names[$i]"
    end
    read -P '# ' n; or return
    test -n "$ids[$n]"; and rp $ids[$n]
end
