function gcos
    # ancestors of HEAD cover the stack below; --contains covers branches stacked above it
    begin
        git branch --no-color --sort=-committerdate --format='%(refname:short)' --no-merged main --merged HEAD
        git branch --no-color --sort=-committerdate --format='%(refname:short)' --no-merged main --contains HEAD
    end | awk '!seen[$0]++' | fzf --header 'git checkout (stack)' | xargs git checkout
end
