# setup
brew update && brew upgrade

brew install fish

# gitconfig
cp ~/.config/.gitconfig ~/.gitconfig

# setup fish as default shell
fish_add_path /opt/homebrew/bin
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish || true
fish || true

# fish plugin manager
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

fisher install jorgebucaran/nvm.fish # node version manager
fisher install edc/bass # bash with fish
fisher install reitzig/sdkman-for-fish # sdkman for fish
fisher install JGAntunes/fish-gvm # gvm for fish

# install life basically
brew install \
    jq yq fish neovim tmux rectangle starship kind \
    gh wget kubectl openvpn-connect fswatch luarocks \
    lazydocker coreutils ko bat ripgrep fd git-delta \
    brew-cask-completion stats zig ghostty
brew tap hashicorp/tap
brew install hashicorp/tap/terraform hashicorp/tap/vault
brew install --cask font-fira-mono-nerd-font
brew install fzf && fzf --fish | source

# dev (java)
curl -s https://get.sdkman.io | bash

# setup rectangle window manager
mkdir -p ~/Library/Application\ Support/Rectangle/
cp ~/.config/RectangleConfig.json ~/Library/Application\ Support/Rectangle/

# dev (go)
brew install go golangci-lint
if ! command -v gvm 2>&1 >/dev/null
then
 bash (curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | psub)
fi
gvm install go1.23.3

# dev (rust)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# dev (lua)
cargo install stylua

# dev (js)
nvm install latest
npm install -g yarn

# dev (java)
sdk install java

# dev (python)
brew install pipx
pipx ensurepath
pipx install poetry
poetry completions fish > ~/.config/fish/completions/poetry.fish

# last cleanup
brew update && brew upgrade
