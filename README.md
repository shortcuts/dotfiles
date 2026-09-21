# dotfiles

Here you'll find what I use on a daily basis, located in my `~/.config` folder

- [nvim](https://github.com/shortcuts/dotfiles/tree/main/nvim)
- [fish](https://github.com/shortcuts/dotfiles/tree/main/fish)
- [tmux](https://github.com/shortcuts/dotfiles/tree/main/tmux)
- [ghostty](https://github.com/shortcuts/dotfiles/tree/main/ghostty)
- [starship](https://github.com/shortcuts/dotfiles/blob/main/starship.toml)
- [AeroSpace](https://github.com/shortcuts/dotfiles/blob/main/aerospace/aerospace.toml)

## getting started

`./install.sh setup`

## update all

`./install.sh`

### cleanup after mise migration

  brew uninstall anomalyco/tap/opencode cask emacs neovim zig
  brew uninstall bat cargo-binstall fastfetch fd fzf gh ghui git-delta glow \
      hostctl hunk jq k9s kind kubectx lazydocker lazygit ko pipx ripgrep \
      shfmt starship tree-sitter hashicorp/tap/terraform hashicorp/tap/vault yq
  brew autoremove
  rm -f ~/.cargo/bin/{tree-sitter,stylua,bob} ~/go/bin/golangci-lint \
        ~/.local/bin/{pipx,poetry}


brew uninstall rtk
pipx uninstall headroom-ai
rm -f ~/.local/bin/headroom   # pipx report symlink broken, so remove leftover by hand

mise use -g aqua:rtk-ai/rtk@latest
mise use -g pipx:headroom-ai@latest

hash -r 2>/dev/null; command -v rtk headroom   # confirm both resolve under mise

Both paths must show ~/.local/share/mise/installs/... or a mise shim. If command -v rtk still print /opt/homebrew/bin/rtk, brew copy remain — re-check brew list rtk.
