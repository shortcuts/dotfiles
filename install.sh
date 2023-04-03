# setup
brew update && brew upgrade

brew tap homebrew/cask-fonts
brew install --cask font-fira-code
brew install --cask font-fira-mono-nerd-font

# install life basically
brew install fish neovim tmux rectangle starship
brew install --cask alacritty --no-quarantine

# setup fish as default shell
echo /usr/local/bin/fish | sudo tee -a /etc/shells && chsh -s /usr/local/bin/fish

# neovim deps etc.
brew install jump bat ripgrep fd git-delta

# install fzf
brew install fzf && /usr/local/opt/fzf/install

# install fish plugin manager
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

# install nvm to manage node versions
fisher install jorgebucaran/nvm.fish

# setup rectangle window manager
mkdir -p ~/Library/Application\ Support/Rectangle/
cp RectangleConfig.json ~/Library/Application\ Support/Rectangle/

# dev
brew install go golangci-lint

# gitconfig
cp .gitconfig ~/.gitconfig
