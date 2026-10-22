.PHONY: install update symlink lint mac linux

# `make install mac`, `make update linux`. Omitted: install.sh detects the host.
PLATFORM := $(filter mac linux,$(MAKECMDGOALS))

install:
	./install.sh setup $(PLATFORM)

update:
	./install.sh update $(PLATFORM)

# Words after install/update are args, not targets.
mac linux:
	@:

symlink:
	rm -rf ~/.claude
	ln -sf ~/.config/.claude ~/.claude

lint:
	shellcheck install.sh
	fish --no-execute fish/config.fish
	fish --no-execute fish/alias.fish
	stylua --check nvim/lua
