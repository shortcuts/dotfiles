.PHONY: install update symlink lint tmux-status tmux-status-test

SANDBOX ?= /tmp/tmux-claude-code-status

install:
	./install.sh setup

update:
	./install.sh

symlink:
	rm -rf ~/.claude
	ln -sf ~/.config/.claude ~/.claude

tmux-status:
	RAW=file://$(CURDIR)/.claude/hooks/tmux-claude-code-status.sh \
		sh tmux-claude-code-status/install.sh

tmux-status-test:
	mkdir -p $(SANDBOX)
	env -u TMUX HOME=$(SANDBOX) XDG_CONFIG_HOME=$(SANDBOX)/.config \
		RAW=file://$(CURDIR)/.claude/hooks/tmux-claude-code-status.sh \
		sh tmux-claude-code-status/install.sh
	@echo "installed under $(SANDBOX)"

lint:
	shellcheck install.sh tmux-claude-code-status/install.sh
	fish --no-execute fish/config.fish
	fish --no-execute fish/alias.fish
	stylua --check nvim/lua
