# The following lines were added by Docker Desktop to add commands to your PATH.
# fish_add_path: export appended a copy per nested shell (tmux, popups)
fish_add_path -a $HOME/.docker/bin
# End of Docker Desktop section.

source ~/.config/fish/alias.fish

# Each `tool init | source` costs 10-260ms, and a new pane starts without our env.
# Replay the output from ~/.cache/fish and rerun the command only when the stamp moves.
# The cache is per machine: its content embeds /opt/homebrew or /usr/local paths.
function __cache_source -a name stamp
    set -l f ~/.cache/fish/$name.fish
    set -l head
    test -f $f; and read head <$f
    if test "$head" != "# $stamp"
        mkdir -p (path dirname $f)
        set -l out ($argv[3..-1]); and printf '%s\n' "# $stamp" $out >$f
    end
    source $f
end

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
if not set -q HOMEBREW_PREFIX
    set -l b (command -s brew)
    __cache_source brew "$b "(path mtime $b) brew shellenv
end

# Real tool paths, not shims: a shim execs the 150MB mise binary, and Falcon
# rescans it every time (~280ms per command). This pays that once per config change.
# Stamped on every config that feeds this PATH, so a long-lived parent (tmux
# server, Ghostty) cannot pin children to a PATH that predates a tool bump.
# Re-runs on cd so a repo's mise.toml pins apply; mise itself only runs when the
# stamp moves. Stamp covers parent dirs (mise walks up) and installs, so a new
# "latest" install is picked up without a config edit.
function __mise_sync --on-variable PWD
    set -l files ~/.config/mise/config.toml
    set -l d $PWD
    while true
        set -a files (path filter -f $d/mise.toml $d/mise.local.toml $d/.mise.toml)
        test $d = /; and break
        set d (path dirname $d)
    end
    set -l stamp $files (path mtime $files ~/.local/share/mise/installs/*)
    set stamp (string join - $stamp)
    test "$__MISE_STAMP" = "$stamp"; and return
    # mise env appends the current PATH, so strip the old tool paths first or a
    # repo's versions outlive leaving the repo.
    set -gx PATH (string match -v -- "$HOME/.local/share/mise/installs/*" $PATH)
    __cache_source mise $stamp __mise_env
    set -gx __MISE_STAMP $stamp
end

# mise prints the whole current PATH. Keep only the entries it adds, so a cached
# copy cannot freeze the PATH of the shell that wrote it.
# eval lets fish undo mise's quoting: entries can contain spaces.
function __mise_env
    mise env -s fish | while read -l line
        set -l m (string match -r '^set -gx PATH (.*)' -- $line)
        if set -q m[2]
            eval set -l entries $m[2]
            set -l new
            for e in $entries
                contains -- $e $PATH; or set -a new (string escape -- $e)
            end
            echo "set -gx PATH $new \$PATH"
        else
            echo $line
        end
    end
end
__mise_sync

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
    set -l fzf (command -s fzf)
    __cache_source fzf "$fzf "(path mtime $fzf) fzf --fish
    # --print-full-init skips the stub that pipes the real init through psub (~15ms)
    set -l ss (command -s starship)
    __cache_source starship "$ss "(path mtime $ss) starship init fish --print-full-init

    # Right prompt in pure fish: a second starship exec costs ~32ms per prompt
    # under Falcon's scanner, and $CMD_DURATION already holds what it printed.
    function fish_right_prompt
        set -l d $CMD_DURATION
        test "$d" -gt 0 2>/dev/null; or return
        set -l dur "$d"ms
        test $d -ge 1000; and set dur (math -s2 $d / 1000)s
        echo -n (set_color -d white)"in "(set_color -o -d yellow)$dur(set_color normal)
    end

    # Rex replaces tmux and sets REX_SESSION in every terminal it opens
    if not set -q TMUX; and not set -q REX_SESSION; and type -q tmux
        tmux attach; or tmux new
    end
end

# Added by codebase-memory-mcp install
fish_add_path /Users/k/.local/bin

# Added by codebase-memory-mcp install
fish_add_path /Users/clement.vannicatte/.local/bin
