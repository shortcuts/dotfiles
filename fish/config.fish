# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/clement.vannicatte/.docker/bin"
export PATH="$PATH:/Users/k/.docker/bin"
# End of Docker Desktop section.

source ~/.config/fish/alias.fish

# Paths — fish_add_path is idempotent, no-op when already present
fish_add_path /usr/local/bin /opt/homebrew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    $HOME/.local/share/bob/nvim-bin \
    $HOME/Documents/no-neck-pain.nvim/.ci/lua-ls \
    /Library/Frameworks/Python.framework/Versions/3.11/bin \
    $HOME/.bun/bin

set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx ANDROID_SDK_ROOT $HOME/Android/Sdk
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools

set -gx KO_DOCKER_REPO ko.local
set -gx BUN_INSTALL $HOME/.bun
set -gx MANPAGER "nvim +Man!"
set -gx EDITOR nvim

# Subshells inherit the env from the first shell; skip the brew spawn then
set -q HOMEBREW_PREFIX; or brew shellenv | source

# Real tool paths, not shims: a shim execs the 150MB mise binary, and Falcon
# rescans it every time (~280ms per command). This pays that once per shell.
# Stamped on config.toml's mtime, so a long-lived parent (tmux server, Ghostty)
# cannot pin children to a PATH that predates a tool being added.
set -l mise_stamp (path mtime ~/.config/mise/config.toml)
if test "$__MISE_STAMP" != "$mise_stamp"
    mise env -s fish | source
    set -gx __MISE_STAMP $mise_stamp
end

if test -f ~/google-cloud-sdk/path.fish.inc
    source ~/google-cloud-sdk/path.fish.inc
end

# Interactive-only: scripts and nvim :! skip all of this
if status is-interactive
    # Load keychain only when the agent is empty
    ssh-add -l >/dev/null 2>&1
    or /usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'
    fzf --fish | source
    starship init fish | source

    # Right prompt in pure fish: a second starship exec costs ~32ms per prompt
    # under Falcon's scanner, and $CMD_DURATION already holds what it printed.
    function __stamp_cmd_start --on-event fish_preexec
        set -g __cmd_start (date +%H:%M:%S)
    end

    function fish_right_prompt
        set -q __cmd_start; or return
        set -l d $CMD_DURATION
        set -l dur "$d"ms
        test $d -ge 1000; and set dur (math -s2 $d / 1000)s
        echo -n (set_color -d white)"in "(set_color -o -d yellow)$dur(set_color -d white)" at $__cmd_start"(set_color normal)
    end

    # Auto-attach tmux, skip if already in tmux
    if not set -q TMUX; and type -q tmux
        tmux attach; or tmux new
    end
end

# Added by codebase-memory-mcp install
fish_add_path /Users/k/.local/bin

# Added by codebase-memory-mcp install
fish_add_path /Users/clement.vannicatte/.local/bin
