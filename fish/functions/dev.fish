function dev
    if not set -q argv[1]
        cd ~/Documents/

        return
    end

    cd ~/Documents/$argv
end
