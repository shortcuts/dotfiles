function gl
    git log --graph --pretty="tformat:$FORMAT" $* |
    column -t -s '{' |
    less -XRS --quit-if-one-screen
end
