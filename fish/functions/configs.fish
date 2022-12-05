function configs
    if not set -q argv[1]
        cd ~/.config/

        return
    end

    cd ~/.config/$argv
end
