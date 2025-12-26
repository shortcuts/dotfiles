MODE=$1

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

echo "mode: $MODE"

# gitconfig
if [[ $MODE == "setup" ]]; then
    cp ~/.config/.gitconfig ~/.gitconfig
fi

# setup
brew update && brew upgrade

brew install fish mise

# brew taps
brew tap hashicorp/tap
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

# fish as default shell
if [[ $MODE == "setup" ]]; then
    fish_add_path /opt/homebrew/bin
    echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
    chsh -s /opt/homebrew/bin/fish || true
    fish || true

    # fish plugin manager
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

    fisher install jorgebucaran/nvm.fish # node version manager
    fisher install edc/bass # bash with fish
else
    fisher update
fi

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

# install life basically
brew install coreutils hostctl \
    ghostty starship tmux \
    btop jq yq wget fswatch bat ripgrep fd fzf \
    kind derailed/k9s/k9s kubectl kubectx jesseduffield/lazydocker/lazydocker ko \
    gh lazygit git-delta \
    openvpn-connect hashicorp/tap/terraform hashicorp/tap/vault \
    stats borders fastfetch nikitabobko/tap/aerospace font-hack-nerd-font \
    luarocks obsidian opencode

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

cargo install bob
bob use latest

# setup fzf
if [[ $MODE == "setup" ]]; then
    fzf --fish | source
fi

# last cleanup
brew update && brew upgrade && brew doctor && brew cleanup
