.PHONY: install update symlink lint

install:
	./install.sh setup

update:
	./install.sh

symlink:
	rm -rf ~/.claude
	ln -sf ~/.config/.claude ~/.claude

lint:
	shellcheck install.sh
	fish --no-execute fish/config.fish
	fish --no-execute fish/alias.fish
	stylua --check nvim/lua
