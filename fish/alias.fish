# git
abbr -a gs   git status -sb
abbr -a ga   git add .
abbr -a gc   git commit -m
abbr -a gca  git commit --amend
abbr -a gcl  git clone
abbr -a gl   git log
abbr -a gd   git diff
abbr -a gf   git fetch origin

# misc
alias reload='exec fish'
alias cat='bat'
alias vim='nvim'
alias v='nvim .'

alias apic='docker exec -it api-clients-automation bash -lc "cd scripts && NODE_NO_WARNINGS=1 node dist/scripts/cli/index.js $argv"'
