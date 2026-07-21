MODE=$1

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

echo "mode: $MODE"

# gitconfig + claude symlink
if [[ $MODE == "setup" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    curl -fsSL https://bun.com/install | bash
    cp ~/.config/.gitconfig ~/.gitconfig
    # symlink ~/.claude -> ~/.config/.claude so skills/settings are tracked in git
    rm -rf ~/.claude
    ln -sf ~/.config/.claude ~/.claude
fi

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

# setup
brew update && brew upgrade

brew install fish mise

# brew taps
brew tap hashicorp/tap
brew tap FelixKratz/formulae
brew tap nikitabobko/tap
brew tap guumaster/tap

# install life basically
brew install coreutils hostctl \
    ghostty starship tmux \
    btop jq yq wget fswatch bat ripgrep fd fzf \
    kind derailed/k9s/k9s kubectl kubectx jesseduffield/lazydocker/lazydocker ko \
    gh lazygit git-delta \
    openvpn-connect hashicorp/tap/terraform hashicorp/tap/vault \
    stats borders fastfetch nikitabobko/tap/aerospace font-hack-nerd-font \
    luarocks obsidian anomalyco/tap/opencode \
    mac-cleanup-py cargo-binstall glow ghui mole shellcheck

brew install --cask font-lilex-nerd-font

# fish as default shell
if [[ $MODE == "setup" ]]; then
    echo $(which fish) | sudo tee -a /etc/shells
    chsh -s $(which fish) || true
    fish || true
    fish_add_path $(which brew)

    # fish plugin manager
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

    fisher install jorgebucaran/nvm.fish # node version manager
    fisher install edc/bass # bash with fish
fi

fisher update
fish_update_completions

# languages

mise use -g zig

mise use -g java

mise use -g go
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
go install mvdan.cc/sh/v3/cmd/shfmt@latest

mise use -g rust

brew install lua
cargo install stylua
cargo binstall tree-sitter-cli

nvm install latest
npm install -g yarn

# ccstatusline: install under mise's global node so the binary path is stable;
# settings.json points statusLine.command at this absolute path so it works
# regardless of which node version a project pins
mise use -g node
mise exec node@latest -- npm install -g ccstatusline

mise use -g python
pip install --upgrade pip
pip install --user pipx
mise plugins install poetry --force
poetry completions fish > ~/.config/fish/completions/poetry.fish

# rpi

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

# lang

luarocks install luacheck
luarocks install argparse

cargo install bob-nvim
bob use latest

# setup fzf
if [[ $MODE == "setup" ]]; then
    fzf --fish | source
fi

# last cleanup
brew update && brew upgrade && brew doctor && brew cleanup

# mission control https://nikitabobko.github.io/AeroSpace/guide#a-note-on-mission-control
defaults write com.apple.dock expose-group-apps -bool true && killall Dock
