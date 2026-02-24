MODE=$1

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

echo "mode: $MODE"

# gitconfig
if [[ $MODE == "setup" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    curl -fsSL https://bun.com/install | bash
    cp ~/.config/.gitconfig ~/.gitconfig
fi

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
    luarocks obsidian opencode

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

mise use -g rust

brew install lua
cargo install stylua

nvm install latest
npm install -g yarn

mise use -g python
pip install --upgrade pip
pip install --user pipx
mise plugins install poetry --force
poetry completions fish > ~/.config/fish/completions/poetry.fish

# rpi

sudo hostctl add domains rpi \
  dashboard.shortcuts.codes \
  wgeasy.shortcuts.codes \
  qbittorrent.shortcuts.codes \
  jellyfin.shortcuts.codes \
  kuma.shortcuts.codes \
  bazarr.shortcuts.codes --ip 192.168.1.19

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
