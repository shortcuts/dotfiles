.PHONY: install update symlink lint tmux-status

# Sandbox HOME by default, so a test run cannot touch the real config.
# Install for real with: make tmux-status TMUX_STATUS_HOME=$HOME
TMUX_STATUS_HOME ?= /tmp/tmux-claude-code-status

install:
	./install.sh setup

update:
	./install.sh

symlink:
	rm -rf ~/.claude
	ln -sf ~/.config/.claude ~/.claude

tmux-status:
	mkdir -p $(TMUX_STATUS_HOME)
	env -u TMUX HOME=$(TMUX_STATUS_HOME) \
		XDG_CONFIG_HOME=$(TMUX_STATUS_HOME)/.config \
		RAW=file://$(CURDIR)/.claude/hooks/tmux-agent-notify.sh \
		sh tmux-claude-code-status/install.sh
	@echo "installed under $(TMUX_STATUS_HOME)"

lint:
	shellcheck install.sh tmux-claude-code-status/install.sh
	fish --no-execute fish/config.fish
	fish --no-execute fish/alias.fish
	stylua --check nvim/lua
