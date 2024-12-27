source ~/.config/fish/alias.fish

# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain ^/dev/null

# Style: duskfox
# Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/duskfox/duskfox.fish
set -l foreground e0def4
set -l selection 433c59
set -l comment 817c9c
set -l red eb6f92
set -l orange ea9a97
set -l yellow f6c177
set -l green a3be8c
set -l purple c4a7e7
set -l cyan 9ccfd8
set -l pink eb98c3

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

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

eval "$(/opt/homebrew/bin/brew shellenv)"

fzf --fish | source

starship init fish | source

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/clement.vannicatte/google-cloud-sdk/path.fish.inc' ]; . '/Users/clement.vannicatte/google-cloud-sdk/path.fish.inc'; end
