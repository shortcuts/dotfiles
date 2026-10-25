#!/usr/bin/env bash
# usage: install.sh [setup|update] [mac|lite]
# lite: the Mac mini agent box. No GUI apps, only what its six projects build with.

MODE=$1
PLATFORM=$2

if [[ $MODE != "setup" ]]; then
    MODE="update"
fi

PLATFORM=${PLATFORM:-mac}

case $PLATFORM in
mac | lite) ;;
*)
    echo "usage: $0 [setup|update] [mac|lite]" >&2
    exit 1
    ;;
esac

echo "mode: $MODE, platform: $PLATFORM"

# ---------------------------------------------------------------- shared mac

# Homebrew, shell bootstrap files and the SDK pin: identical on both platforms.
mac_base() {
    [[ $MODE == "setup" ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # ssh-agent: load keychain keys for non-fish shells too (bash/zsh subprocesses,
    # e.g. Claude Code tool calls, don't source config.fish)
    [[ -f ~/.zshenv ]] || cat > ~/.zshenv <<'EOF'
# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1
EOF

    [[ -f ~/.bashrc ]] || cat > ~/.bashrc <<'EOF'
# Load all saved ssh keys
/usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1
EOF

    [[ -f ~/.bash_profile ]] || cat > ~/.bash_profile <<'EOF'
[ -f ~/.bashrc ] && source ~/.bashrc
EOF

    [[ -f ~/.ssh/config ]] || (mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat > ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes

Host github.com
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 ~/.ssh/config)

    # The Homebrew installer does not add brew to this shell's PATH.
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

    # xcrun defaults to the newest SDK, which a beta SDK can make newer than the CLT linker supports.
    local sdk="$(xcode-select -p)/SDKs/MacOSX.sdk"
    [[ -d $sdk ]] && export SDKROOT=$sdk

    brew update && brew upgrade
}

# ---------------------------------------------------------------- mac

mac_pre() {
    mac_base

    # Loads config.mac.toml on top of config.toml. Machine-local (gitignored):
    # the lite mini must not get it, and fish reads it on every shell.
    printf 'env = ["mac"]\n' > ~/.config/mise/miserc.toml

    brew install fish mise

    # brew taps
    brew tap FelixKratz/formulae
    brew tap nikitabobko/tap

    # GNU coreutils, not the uutils rewrite mise's registry points at.
    # tmux and btop stay on brew: the static mise builds are less tested against macOS terminfo.
    # Everything else here is a cask, a daemon, or absent from mise's registry.
    brew install coreutils tmux wget fswatch btop \
        ghostty openvpn-connect obsidian font-hack-nerd-font \
        stats felixkratz/formulae/borders nikitabobko/tap/aerospace \
        luarocks mac-cleanup-py mole

    brew install --cask font-lilex-nerd-font font-jetbrains-mono-nerd-font font-fira-mono-nerd-font \
        docker-desktop android-commandlinetools android-platform-tools \
        google-chrome spotify bambu-studio
    brew install lua
}

mac_post() {
    # rpi (needs sudo, one-time)
    if [[ $MODE == "setup" ]]; then
        sudo hostctl add domains rpi \
            dashboard.shrtcts.fr \
            wgeasy.shrtcts.fr \
            proxy.shrtcts.fr \
            qbittorrent.shrtcts.fr \
            jellyfin.shrtcts.fr \
            kuma.shrtcts.fr \
            openbao.shrtcts.fr \
            observability.shrtcts.fr \
            renovaite.shrtcts.fr \
            renovaite-api.shrtcts.fr --ip 192.168.1.19
    fi

    # start-at-login only registers the login item once AeroSpace has run.
    open -a AeroSpace

    # last cleanup
    brew update && brew upgrade && brew doctor && brew cleanup

    # mission control https://nikitabobko.github.io/AeroSpace/guide#a-note-on-mission-control
    # killall Dock is disruptive, keep it out of routine updates
    if [[ $MODE == "setup" ]]; then
        defaults write com.apple.dock expose-group-apps -bool true && killall Dock

        # reduce motion and transparency; takes effect after next login
        defaults write com.apple.Accessibility DifferentiateWithoutColor -int 1
        defaults write com.apple.Accessibility ReduceMotionEnabled -int 1
        defaults write com.apple.universalaccess reduceMotion -int 1
        defaults write com.apple.universalaccess reduceTransparency -int 1
    fi
}

# ---------------------------------------------------------------- lite

lite_pre() {
    mac_base

    # Lite has no config.mac.toml: keep the full Mac's tool set off the small disk.
    rm -f ~/.config/mise/miserc.toml

    # No window manager, browser or media apps. Rex runs the agent sessions; tmux stays as
    # its fallback and because the tpm step below needs it.
    # luarocks and lua serve no-neck-pain.nvim; clang-format serves pgpemu's `make format`.
    # wireguard-tools serves the `vpn` fish function.
    # btop is the mini's resource monitor.
    brew install fish mise tmux coreutils lua luarocks clang-format wireguard-tools btop

    brew install --cask font-jetbrains-mono-nerd-font \
        android-commandlinetools android-platform-tools love

    lite_prune
}

# Removes what an earlier full-Mac install left behind. Each step is a no-op once it is clean.
# The lists mirror the mac_pre packages that lite does not install.
lite_prune() {
    local pkg link
    for pkg in borders mac-cleanup-py mole; do
        brew list --formula "$pkg" >/dev/null 2>&1 && brew uninstall --formula "$pkg"
    done
    # --zap also deletes app data: Docker images, browser profiles.
    for pkg in aerospace ghostty openvpn-connect obsidian stats docker-desktop google-chrome \
        spotify bambu-studio font-hack-nerd-font font-lilex-nerd-font font-fira-mono-nerd-font; do
        brew list --cask "$pkg" >/dev/null 2>&1 && brew uninstall --cask --zap "$pkg"
    done
    brew untap felixkratz/formulae nikitabobko/tap 2>/dev/null

    # mise prune keeps every version a tracked config still names, and config.mac.toml is
    # still on disk. Untrack it so the prune in the shared section drops the mac-only tools.
    for link in ~/.local/state/mise/tracked-configs/*; do
        [[ $(readlink "$link") == */mise/config.mac.toml ]] && rm "$link"
    done

    # Generated by the mac setup only.
    rm -f ~/.config/fish/completions/poetry.fish
}

# Writes /Library/LaunchDaemons/<label>.plist and loads it. A daemon with UserName runs at boot
# without a GUI login; a LaunchAgent would wait for one, and the mini boots headless.
# usage: install_daemon <label> <extra plist keys> <program> [args...]
# Reloads only when the plist changed: a reload would kill a running job.
# Runs as the current user; set DAEMON_USER=root for a job that needs root.
install_daemon() {
    local label=$1 extra=$2 plist=/Library/LaunchDaemons/$1.plist args="" arg new
    local user=${DAEMON_USER:-$(id -un)}
    shift 2
    for arg in "$@"; do
        args+="    <string>$arg</string>"$'\n'
    done
    new=$(mktemp)
    cat >"$new" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>UserName</key><string>$user</string>
  <key>EnvironmentVariables</key><dict><key>HOME</key><string>$HOME</string></dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/$label.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/$label.log</string>
  <key>ProgramArguments</key>
  <array>
$args  </array>
$extra</dict>
</plist>
EOF
    plutil -lint "$new" >/dev/null || return 1
    if ! sudo cmp -s "$new" "$plist"; then
        sudo install -m 644 -o root -g wheel "$new" "$plist"
        sudo launchctl bootout "system/$label" 2>/dev/null
    fi
    sudo launchctl print "system/$label" >/dev/null 2>&1 || sudo launchctl bootstrap system "$plist"
    rm -f "$new"
}

# The mini runs agents 24/7 with no display: stay awake, recover from power loss, keep
# background work off the 8 GB RAM and 128 GB disk. macOS upgrades can reset pmset: rerun update.
lite_headless() {
    # A desktop needs no disablesleep; that flag targets laptops.
    sudo pmset -a sleep 0 disksleep 0 displaysleep 0 powernap 0 standby 0 \
        autopoweroff 0 hibernatemode 0 womp 1 autorestart 1
    sudo systemsetup -setrestartfreeze on
    # hibernatemode 0 never reads it, and it takes as much disk as RAM.
    sudo rm -f /var/vm/sleepimage

    # An unattended macOS update reboots the box under running agents: update by hand.
    sudo mdutil -a -i off >/dev/null
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    sudo defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false

    # Each rustc job is heavy on 8 GB. Only written when absent: cargo config is user-owned.
    [[ -f ~/.cargo/config.toml ]] || {
        mkdir -p ~/.cargo
        printf '[build]\njobs = 2\n' >~/.cargo/config.toml
    }

    # Remote Login is how the phone and laptop reach the mini over the tunnel. Needs Full Disk
    # Access for the terminal on recent macOS, so a failure prints the manual step.
    sudo systemsetup -setremotelogin on ||
        echo "enable Remote Login by hand: System Settings > General > Sharing"
    # Keys only: the mini has no screen to show a brute-force attempt. Skipped without a key,
    # so the hardening cannot lock out the only way in. sshd keeps the first value it reads:
    # 050 sorts before Apple's 100-macos.conf.
    if [[ -s ~/.ssh/authorized_keys ]]; then
        printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' |
            sudo tee /etc/ssh/sshd_config.d/050-headless.conf >/dev/null
    else
        echo "no ~/.ssh/authorized_keys, SSH password login stays on"
    fi

    # After a power loss the mini boots to the login screen: the login keychain stays locked,
    # so claude's token and the ssh keys are unavailable. Auto-login needs FileVault off.
    if [[ $(fdesetup status) == *"is Off"* ]]; then
        [[ $(sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null) == $(id -un) ]] ||
            sudo sysadminctl -autologin set -userName "$(id -un)" -password -
    else
        echo "FileVault is on: after a power loss the mini waits for a login. Turn it off for unattended boots."
    fi

    # The launchd jobs reopen their log on every start, so rotation by newsyslog is safe.
    local label
    for label in rex-server cleandisk vpn; do
        echo "$HOME/Library/Logs/com.shortcuts.$label.log $(id -un):staff 644 3 1024 * Z"
    done | sudo tee /etc/newsyslog.d/com.shortcuts.conf >/dev/null

    # `rex server start` is idempotent and detaches, so a server started by hand is left alone.
    # StartInterval makes this job the supervisor: a dead server comes back within a minute.
    # AbandonProcessGroup stops launchd from killing the detached server when this job exits.
    if command -v rex >/dev/null 2>&1; then
        install_daemon com.shortcuts.rex-server \
            '  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>60</integer>
  <key>AbandonProcessGroup</key><true/>
' "$(command -v rex)" server start
    else
        echo "rex not found, skipping rex server daemon"
    fi

    # Daily check; cleandisk --auto does nothing above 20 GiB free. A login shell gives it mise's PATH.
    install_daemon com.shortcuts.cleandisk \
        '  <key>StartCalendarInterval</key><dict><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
  <key>Nice</key><integer>10</integer>
  <key>LowPriorityIO</key><true/>
' "$(command -v fish)" -l -c 'cleandisk --auto'

    # The tunnel is how the phone and laptop reach the mini. wg-quick needs root. KeepAlive
    # retries after a failure, because the LAN can be down when the daemon starts at boot.
    # The conf comes from rpi/bootstrap-mac-client.sh, which also wrote com.wireguard.wg0: replace it.
    local wg_prefix
    wg_prefix=$(brew --prefix)
    if [[ -x $wg_prefix/bin/wg-quick && -f $wg_prefix/etc/wireguard/wg0.conf ]]; then
        sudo launchctl bootout system/com.wireguard.wg0 2>/dev/null
        sudo rm -f /Library/LaunchDaemons/com.wireguard.wg0.plist
        DAEMON_USER=root install_daemon com.shortcuts.vpn \
            '  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ThrottleInterval</key><integer>30</integer>
' /bin/sh -c "PATH=$wg_prefix/bin:\$PATH; wg show interfaces | grep -q . || wg-quick up wg0"
    else
        echo "wg0.conf or wg-quick not found, skipping vpn daemon"
    fi
}

lite_post() {
    # The path pgpemu's Makefile sources. ESP-IDF's installer fetches its own cmake,
    # ninja and ccache, so mise does not carry them.
    local idf=~/esp/v5.4.1/esp-idf
    [[ -d $idf ]] || git clone -b v5.4.1 --depth 1 --recursive \
        https://github.com/espressif/esp-idf.git "$idf"
    [[ -d ~/.espressif ]] || "$idf/install.sh" esp32c3

    # radin is a Claude Code plugin: it needs the claude CLI that mise just installed.
    # --yes takes the default package manager for its companions; --update skips
    # companions already present. A failure here must not stop the run.
    if command -v claude >/dev/null 2>&1; then
        local radin_args=(--yes)
        [[ $MODE == update ]] && radin_args+=(--update)
        curl -fsSL https://raw.githubusercontent.com/shortcuts/radin/main/install.sh |
            bash -s -- "${radin_args[@]}" || echo "radin install failed, run it again by hand"
    else
        echo "claude CLI not found, skipping radin install"
    fi

    lite_headless

    # The default cleanup keeps downloads for 120 days: too long for a 128 GB disk.
    brew cleanup --prune=all -s
}

# ---------------------------------------------------------------- shared

"${PLATFORM}_pre"

# gitconfig + claude symlink
if [[ $MODE == "setup" ]]; then
    [[ $PLATFORM == mac ]] && curl -fsSL https://bun.com/install | bash
    cp ~/.config/.gitconfig ~/.gitconfig
    make -C ~/.config symlink
fi

# tmux plugins: after the package manager, tpm needs tmux installed
[[ -d ~/.tmux/plugins/tpm ]] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
# direct action skips the wizard menu; its reload of ~/.tmux.conf fails harmlessly
bash ~/.tmux/plugins/tmux-agent-sidebar/install-wizard.sh download-binary </dev/null || true

# fish as default shell
if [[ $MODE == "setup" ]]; then
    grep -qxF "$(which fish)" /etc/shells || which fish | sudo tee -a /etc/shells
    chsh -s "$(which fish)" || true
fi

# fish functions do not exist in bash
fish -c fish_update_completions

# languages and CLIs: versions live in mise/config.toml
mise install
mise prune --yes

# This script runs in bash, which never loads fish/config.fish: put the new tools on PATH.
eval "$(mise env -s bash)"

# fff MCP server for Claude Code (user scope, stored in ~/.claude.json)
if ! command -v fff-mcp >/dev/null 2>&1; then
    echo "fff-mcp not found, skipping fff MCP registration"
elif command -v claude >/dev/null 2>&1; then
    claude mcp get fff >/dev/null 2>&1 || claude mcp add --scope user fff -- fff-mcp
else
    echo "claude CLI not found, skipping fff MCP registration"
fi

[[ $PLATFORM == mac ]] && poetry completions fish > ~/.config/fish/completions/poetry.fish

# lang
luarocks install luacheck
luarocks install argparse

bob use latest

"${PLATFORM}_post"
