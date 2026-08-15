source ~/.config/fish/alias.fish

# Paths — fish_add_path is idempotent, no-op when already present
fish_add_path /usr/local/bin /opt/homebrew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    $HOME/.local/share/bob/nvim-bin \
    $HOME/Documents/no-neck-pain.nvim/.ci/lua-ls \
    /Library/Frameworks/Python.framework/Versions/3.11/bin \
    $HOME/.bun/bin \
    $HOME/.local/share/mise/shims

set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx ANDROID_SDK_ROOT $HOME/Android/Sdk
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools

set -gx KO_DOCKER_REPO ko.local
set -gx BUN_INSTALL $HOME/.bun
set -gx MANPAGER "nvim +Man!"
set -gx EDITOR nvim

# Subshells inherit the env from the first shell; skip the brew spawn then
set -q HOMEBREW_PREFIX; or brew shellenv | source

if test -f ~/google-cloud-sdk/path.fish.inc
    source ~/google-cloud-sdk/path.fish.inc
end

# Interactive-only: scripts and nvim :! skip all of this
if status is-interactive
    # No `mise activate`: shims (already in PATH) resolve versions per directory
    # and skip the ~380ms hook-env spawn. Tradeoff: .mise.toml [env] vars no
    # longer auto-load; restore the activate line if a project needs them.

    # Load keychain only when the agent is empty
    ssh-add -l >/dev/null 2>&1
    or /usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'
    fzf --fish | source
    starship init fish | source
    zoxide init fish | source

    # Auto-attach tmux, skip if already in tmux
    if not set -q TMUX; and type -q tmux
        tmux attach; or tmux new
    end
end
