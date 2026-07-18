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

set -Ux ANDROID_HOME $HOME/Android/Sdk
set -Ux ANDROID_SDK_ROOT $HOME/Android/Sdk
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
fish_add_path $ANDROID_HOME/platform-tools

set -x KO_DOCKER_REPO ko.local

set brewbin (which brew)

eval "$($brewbin shellenv)"

fzf --fish | source

starship init fish | source

export MANPAGER="nvim +Man!"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '~/google-cloud-sdk/path.fish.inc' ]; . '~/google-cloud-sdk/path.fish.inc'; end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Auto-attach tmux, skip if already in tmux
if status is-interactive
    and not set -q TMUX
    and type -q tmux
    tmux attach; or tmux new
end
