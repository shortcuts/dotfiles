#!/usr/bin/env bash
# usage: install.sh [setup|update] [mac|linux]

MODE=$1
PLATFORM=$2

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

# Default from the host so a bare `./install.sh setup` keeps working on either OS.
if [[ -z $PLATFORM ]]; then
    [[ $(uname -s) == Linux ]] && PLATFORM=linux || PLATFORM=mac
fi

case $PLATFORM in
mac | linux) ;;
*)
    echo "usage: $0 [setup|update] [mac|linux]" >&2
    exit 1
    ;;
esac

echo "mode: $MODE, platform: $PLATFORM"

# ---------------------------------------------------------------- mac

mac_pre() {
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

    brew install fish mise

    # brew taps
    brew tap FelixKratz/formulae
    brew tap nikitabobko/tap

    # GNU coreutils, not the uutils rewrite mise's registry points at.
    # tmux and btop stay on brew here: mise/config.toml only installs them on linux.
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
    fi
}

# ---------------------------------------------------------------- linux

linux_pre() {
    sudo apt-get update && sudo apt-get -y upgrade

    # No GUI here: headless agent box, reached over ssh.
    # Only what mise cannot ship: the login shell, the sshd daemon, and tools absent
    # from its registry. tmux and btop come from mise/config.toml.
    sudo apt-get install -y build-essential curl git wget unzip \
        fish fswatch luarocks lua5.4 openssh-server pciutils

    # mise ships no apt package in the default repos.
    command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"

    # Mac mini 2018 (Intel): the firmware stays off after a power cut unless told otherwise.
    # Skipped silently on other hardware.
    if [[ $MODE == "setup" ]] && command -v setpci >/dev/null 2>&1; then
        sudo setpci -s 00:1f.0 0xa4.b=0 2>/dev/null || true
    fi
}

linux_post() {
    sudo apt-get -y autoremove
}

# ---------------------------------------------------------------- shared

"${PLATFORM}_pre"

# gitconfig + claude symlink
if [[ $MODE == "setup" ]]; then
    curl -fsSL https://bun.com/install | bash
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

poetry completions fish > ~/.config/fish/completions/poetry.fish

# lang
luarocks install luacheck
luarocks install argparse

bob use latest

"${PLATFORM}_post"
