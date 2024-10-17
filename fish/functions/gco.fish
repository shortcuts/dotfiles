function gco
    git branch --no-color --sort=-committerdate --format='%(refname:short)' | fzf --header 'git checkout' | xargs git checkout
end
