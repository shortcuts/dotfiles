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

brew shellenv | source

if test -f ~/google-cloud-sdk/path.fish.inc
    source ~/google-cloud-sdk/path.fish.inc
end

# Interactive-only: scripts, nvim :! and herdr pane spawns skip all of this
if status is-interactive
    mise activate fish | source

    # Load keychain only when the agent is empty
    ssh-add -l >/dev/null 2>&1
    or /usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1

    fzf --fish | source
    starship init fish | source

    # Auto-attach herdr, skip if already inside a herdr pane
    if not set -q HERDR_ENV; and type -q herdr
        herdr --session home
    end
end
