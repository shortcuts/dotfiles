# setup
brew update && brew upgrade

brew tap homebrew/cask-fonts
brew install --cask font-fira-mono-nerd-font

# install life basically
brew install jq yq fish neovim tmux rectangle starship kind gh wget kubectl openvpn-connect fswatch
brew tap hashicorp/tap
brew install hashicorp/tap/terraform hashicorp/tap/vault
brew install --cask alacritty --no-quarantine

# setup fish as default shell
fish && chsh -s (command -s fish)

# neovim and code utils
brew install bat ripgrep fd git-delta

# fzf for tmux
brew install fzf && /opt/homebrew/opt/fzf/install

# fish plugin manager
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

fisher install jorgebucaran/nvm.fish # node version manager
fisher install edc/bass # bash with fish

# setup rectangle window manager
mkdir -p ~/Library/Application\ Support/Rectangle/
cp RectangleConfig.json ~/Library/Application\ Support/Rectangle/

# dev (go)
brew install go golangci-lint
bash (curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | psub)
gvm install go1.21.4

# dev (rust)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# dev (js)
nvm install latest
npm install -g yarn

# gitconfig
cp .gitconfig ~/.gitconfig
