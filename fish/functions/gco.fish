function gco
    if not set -q argv[1]
        git checkout -
    else
        git checkout $argv[1]
    end
end
