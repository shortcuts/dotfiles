# setup
brew update && brew upgrade

# install kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# install life basically
brew install fish neovim tmux rectangle starship

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
