.PHONY: install update symlink lint mac lite

# `make install mac`, `make update lite`. Omitted: install.sh defaults to mac.
PLATFORM := $(filter mac lite,$(MAKECMDGOALS))

install:
	./install.sh setup $(PLATFORM)

update:
	./install.sh update $(PLATFORM)

# Words after install/update are args, not targets.
mac lite:
	@:

symlink:
	rm -rf ~/.claude
	ln -sf ~/.config/.claude ~/.claude

lint:
	shellcheck install.sh
	fish --no-execute fish/config.fish
	fish --no-execute fish/alias.fish
	stylua --check nvim/lua
