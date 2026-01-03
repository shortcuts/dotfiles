source ~/.config/fish/alias.fish

# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain ^/dev/null

# Paths
set -U fish_user_paths /usr/local/bin $fish_user_paths
set -U fish_user_paths $HOME/.local/bin $fish_user_paths
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths
set -U fish_user_paths $HOME/go/bin $fish_user_paths
set -U fish_user_paths $HOME/.local/share/bob/nvim-bin $fish_user_paths
set -U fish_user_paths $HOME/Documents/no-neck-pain.nvim/.ci/lua-ls $fish_user_paths
set -U fish_user_paths /Library/Frameworks/Python.framework/Versions/3.11/bin $fish_user_paths

# pyenv
set -Ux PYENV_ROOT $HOME/.pyenv
set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths

pyenv init - | source

set -x KO_DOCKER_REPO ko.local

set brewbin (which brew)

eval "$($brewbin shellenv)"

fzf --fish | source

starship init fish | source

export MANPAGER="nvim +Man!"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '~/google-cloud-sdk/path.fish.inc' ]; . '~/google-cloud-sdk/path.fish.inc'; end
