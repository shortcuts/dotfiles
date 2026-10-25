#!/usr/bin/env bash
# usage: install.sh [setup|update] [mac|lite]
# lite: the Mac mini agent box. No GUI apps, only what its six projects build with.

MODE=$1
PLATFORM=$2

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

PLATFORM=${PLATFORM:-mac}

case $PLATFORM in
mac | lite) ;;
*)
    echo "usage: $0 [setup|update] [mac|lite]" >&2
    exit 1
    ;;
esac

echo "mode: $MODE, platform: $PLATFORM"

# ---------------------------------------------------------------- shared mac

# Homebrew, shell bootstrap files and the SDK pin: identical on both platforms.
mac_base() {
    [[ $MODE == "setup" ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # ssh-agent: load keychain keys for non-fish shells too (bash/zsh subprocesses,
    # e.g. Claude Code tool calls, don't source config.fish)
    [[ -f ~/.zshenv ]] || cat > ~/.zshenv <<'EOF'
# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1
EOF

    [[ -f ~/.bashrc ]] || cat > ~/.bashrc <<'EOF'
# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1
EOF

    [[ -f ~/.bash_profile ]] || cat > ~/.bash_profile <<'EOF'
[ -f ~/.bashrc ] && source ~/.bashrc
EOF

    [[ -f ~/.ssh/config ]] || (mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat > ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes

Host github.com
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 ~/.ssh/config)

    # The Homebrew installer does not add brew to this shell's PATH.
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

    # xcrun defaults to the newest SDK, which a beta SDK can make newer than the CLT linker supports.
    local sdk="$(xcode-select -p)/SDKs/MacOSX.sdk"
    [[ -d $sdk ]] && export SDKROOT=$sdk

    brew update && brew upgrade
}

# ---------------------------------------------------------------- mac

mac_pre() {
    mac_base

    # Loads config.mac.toml on top of config.toml. Machine-local (gitignored):
    # the lite mini must not get it, and fish reads it on every shell.
    printf 'env = ["mac"]\n' > ~/.config/mise/miserc.toml

    brew install fish mise

    # brew taps
    brew tap FelixKratz/formulae
    brew tap nikitabobko/tap

    # GNU coreutils, not the uutils rewrite mise's registry points at.
    # tmux and btop stay on brew: the static mise builds are less tested against macOS terminfo.
    # Everything else here is a cask, a daemon, or absent from mise's registry.
    brew install coreutils tmux wget fswatch btop \
        ghostty openvpn-connect obsidian font-hack-nerd-font \
        stats felixkratz/formulae/borders nikitabobko/tap/aerospace \
        luarocks mac-cleanup-py mole

    brew install --cask font-lilex-nerd-font font-jetbrains-mono-nerd-font font-fira-mono-nerd-font \
        docker-desktop android-commandlinetools android-platform-tools \
        google-chrome spotify bambu-studio
    brew install lua
}

mac_post() {
    # rpi (needs sudo, one-time)
    if [[ $MODE == "setup" ]]; then
        sudo hostctl add domains rpi \
            dashboard.shrtcts.fr \
            wgeasy.shrtcts.fr \
            proxy.shrtcts.fr \
            qbittorrent.shrtcts.fr \
            jellyfin.shrtcts.fr \
            kuma.shrtcts.fr \
            openbao.shrtcts.fr \
            observability.shrtcts.fr \
            renovaite.shrtcts.fr \
            renovaite-api.shrtcts.fr --ip 192.168.1.19
    fi

    # start-at-login only registers the login item once AeroSpace has run.
    open -a AeroSpace

    # last cleanup
    brew update && brew upgrade && brew doctor && brew cleanup

    # mission control https://nikitabobko.github.io/AeroSpace/guide#a-note-on-mission-control
    # killall Dock is disruptive, keep it out of routine updates
    if [[ $MODE == "setup" ]]; then
        defaults write com.apple.dock expose-group-apps -bool true && killall Dock

        # reduce motion and transparency; takes effect after next login
        defaults write com.apple.Accessibility DifferentiateWithoutColor -int 1
        defaults write com.apple.Accessibility ReduceMotionEnabled -int 1
        defaults write com.apple.universalaccess reduceMotion -int 1
        defaults write com.apple.universalaccess reduceTransparency -int 1
    fi
}

# ---------------------------------------------------------------- lite

lite_pre() {
    mac_base

    # Lite has no config.mac.toml: keep the full Mac's tool set off the small disk.
    rm -f ~/.config/mise/miserc.toml

    # No window manager, browser or media apps. tmux and ghostty stay for the agent sessions.
    # luarocks and lua serve no-neck-pain.nvim; clang-format serves pgpemu's `make format`.
    brew install fish mise tmux coreutils lua luarocks clang-format ghostty

    brew install --cask font-jetbrains-mono-nerd-font \
        android-commandlinetools android-platform-tools love
}

lite_post() {
    # The path pgpemu's Makefile sources. ESP-IDF's installer fetches its own cmake,
    # ninja and ccache, so mise does not carry them.
    local idf=~/esp/v5.4.1/esp-idf
    [[ -d $idf ]] || git clone -b v5.4.1 --depth 1 --recursive \
        https://github.com/espressif/esp-idf.git "$idf"
    [[ -d ~/.espressif ]] || "$idf/install.sh" esp32c3

    # radin is a Claude Code plugin: it needs the claude CLI that mise just installed.
    # --yes takes the default package manager for its companions; --update skips
    # companions already present. A failure here must not stop the run.
    if command -v claude >/dev/null 2>&1; then
        local radin_args=(--yes)
        [[ $MODE == update ]] && radin_args+=(--update)
        curl -fsSL https://raw.githubusercontent.com/shortcuts/radin/main/install.sh |
            bash -s -- "${radin_args[@]}" || echo "radin install failed, run it again by hand"
    else
        echo "claude CLI not found, skipping radin install"
    fi

    brew cleanup
}

# ---------------------------------------------------------------- shared

"${PLATFORM}_pre"

# gitconfig + claude symlink
if [[ $MODE == "setup" ]]; then
    [[ $PLATFORM == mac ]] && curl -fsSL https://bun.com/install | bash
    cp ~/.config/.gitconfig ~/.gitconfig
    make -C ~/.config symlink
fi

# tmux plugins: after the package manager, tpm needs tmux installed
[[ -d ~/.tmux/plugins/tpm ]] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
# direct action skips the wizard menu; its reload of ~/.tmux.conf fails harmlessly
bash ~/.tmux/plugins/tmux-agent-sidebar/install-wizard.sh download-binary </dev/null || true

# fish as default shell
if [[ $MODE == "setup" ]]; then
    grep -qxF "$(which fish)" /etc/shells || which fish | sudo tee -a /etc/shells
    chsh -s "$(which fish)" || true
fi

# fish functions do not exist in bash
fish -c fish_update_completions

# languages and CLIs: versions live in mise/config.toml
mise install
mise prune --yes

# This script runs in bash, which never loads fish/config.fish: put the new tools on PATH.
eval "$(mise env -s bash)"

# fff MCP server for Claude Code (user scope, stored in ~/.claude.json)
if ! command -v fff-mcp >/dev/null 2>&1; then
    echo "fff-mcp not found, skipping fff MCP registration"
elif command -v claude >/dev/null 2>&1; then
    claude mcp get fff >/dev/null 2>&1 || claude mcp add --scope user fff -- fff-mcp
else
    echo "claude CLI not found, skipping fff MCP registration"
fi

[[ $PLATFORM == mac ]] && poetry completions fish > ~/.config/fish/completions/poetry.fish

# lang
luarocks install luacheck
luarocks install argparse

bob use latest

"${PLATFORM}_post"
