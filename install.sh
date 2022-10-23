# setup
brew update && brew upgrade

# install fish
brew install fish

# install nvim
brew install neovim

# utils that makes life easier
brew install bat
brew install ripgrep
brew install fd

# setup fish as default shell
echo /usr/local/bin/fish | sudo tee -a /etc/shells && chsh -s /usr/local/bin/fish

## installs tools
brew install jump

# install fzf
brew install fzf && /usr/local/opt/fzf/install

# install prompt
brew install starship

# install fish plugin manager
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

# install nvm
fisher install jorgebucaran/nvm.fish

# install window manager
brew install --cask rectangle
mkdir -p ~/Library/Application\ Support/Rectangle/
mv RectangleConfig.json ~/Library/Application\ Support/Rectangle/
