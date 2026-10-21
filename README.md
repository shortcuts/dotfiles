# dotfiles

Here you'll find what I use on a daily basis, located in my `~/.config` folder

- [nvim](https://github.com/shortcuts/dotfiles/tree/main/nvim)
- [fish](https://github.com/shortcuts/dotfiles/tree/main/fish)
- [rex](https://github.com/shortcuts/dotfiles/tree/main/rex) (default terminal and multiplexer)
- [tmux](https://github.com/shortcuts/dotfiles/tree/main/tmux)
- [ghostty](https://github.com/shortcuts/dotfiles/tree/main/ghostty) (fallback with tmux)
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
  brew uninstall actionlint ansible bats-core biome ccache cfssl cloc cmake \
      dotenv-linter eksctl git-cliff go-task gum helm@3 helmfile k3d ktlint \
      kubeconform kustomize minikube mkcert pnpm ruff skaffold vale yamllint zoxide
  brew autoremove
  rm -f ~/.cargo/bin/{tree-sitter,stylua,bob} ~/go/bin/golangci-lint \
        ~/.local/bin/{pipx,poetry}

`ansible` installs through mise's pypi backend, which shells out to `uvx`, so `uv`
is in `mise/config.toml` too. Run `mise install` before the uninstall above.

These stay on brew, absent from mise's registry: `docker`, `git`, `glances`,
`graphviz`, `markdownlint-cli`, `nmap`, `oasdiff`, `parallel`, `pgcli`, `skopeo`,
`slides`, `sqlfluff`. `azure-cli` and `clang-format` stay too. mise only offers them
through pypi and conda, which is a worse trade than brew's bottle.

On the Intel Mac, check every binary resolves under mise after the uninstall.
An aqua package can ship arm64 assets only, and `delta` already needed a pin for that:

    for t in (mise ls --current --json | jq -r 'keys[]')
        command -v $t
    end


brew uninstall rtk
pipx uninstall headroom-ai
rm -f ~/.local/bin/headroom   # pipx report symlink broken, so remove leftover by hand

mise use -g aqua:rtk-ai/rtk@latest
mise use -g pipx:headroom-ai@latest

hash -r 2>/dev/null; command -v rtk headroom   # confirm both resolve under mise

Both paths must show ~/.local/share/mise/installs/... or a mise shim. If command -v rtk still print /opt/homebrew/bin/rtk, brew copy remain — re-check brew list rtk.

### cleanup after claude-code migration

`claude-code` moves from the brew cask to mise. Run the uninstall outside a Claude
Code session: it deletes the binary the session runs from.

    brew uninstall --cask claude-code
    mise install claude-code
    hash -r 2>/dev/null; command -v claude   # must resolve under mise, not /opt/homebrew/bin

### cleanup of empty taps

Every tap below lost its last formula to mise. `brew update` warns about untrusted
taps, so an empty tap costs a warning for nothing.

    brew untap anomalyco/tap asmvik/formulae bjarneo/cliamp derailed/k9s go-task/tap \
        golangci/tap guumaster/tap jesseduffield/lazydocker kitlangton/tap \
        oclint/formulae tw93/tap

Keep `tufin/tufin` (`oasdiff`) and the cask taps `nikitabobko`, `lihaoyun6`,
`daveshanley`, `playcover`. `brew list --cask --full-name` prints short names, so
count cask taps with `brew list --cask` before you untap.

Silence the warning for the taps that stay. Per-formula trust covers only what is
installed, unlike whole-tap trust:

    brew trust --formula algolia/algolia-cli/algolia azure/kubelogin/kubelogin \
        dart-lang/dart/dart felixkratz/formulae/borders \
        omissis/go-jsonschema/go-jsonschema thomaspoignant/tap/go-feature-flag-cli \
        tinygo-org/tools/tinygo tufin/tufin/oasdiff
    brew trust --cask daveshanley/vacuum/vacuum lihaoyun6/tap/quickrecorder \
        nikitabobko/tap/aerospace@0.19.2

### eMudhra CA key leak (October 2026)

Eight eMudhra intermediate CAs leaked their private keys. Details:
<https://emudhra.we-have-a-problem.com/>. Browsers block the certificates. Command-line
tools can still trust them, so patch each CA bundle.

Upgrade the tools that ship their own bundle:

    brew upgrade ca-certificates uv    # ca-certificates >= 2026-09-25_1, uv >= 0.13.4
    mise upgrade node                  # node >= 26.12.1
    python -m pip install -U pip       # pip >= 26.2.2

Go 1.27.3 already has the fix.

macOS does not patch `/etc/ssl/cert.pem`. The built-in `curl`, `git`, `python3` and
`openssl` read it, and it does not check revocation. Remove the two affected roots by
hand. The script keeps a backup in `cert.pem.bak`:

    sudo cp -p /etc/ssl/cert.pem /etc/ssl/cert.pem.bak &&
    sudo awk '/^(###|===) /{skip=0}
      /^=== .*\/CN=(AAA Certificate Services|emSign ECC Root CA - G3)$/{skip=1}
      !skip' /etc/ssl/cert.pem.bak | sudo tee /etc/ssl/cert.pem > /dev/null

Check the result. The `grep` must print `0`. Each `curl` must fail with a certificate error:

    grep -cE 'AAA Certificate Services|emSign ECC Root CA - G3' /etc/ssl/cert.pem
    /usr/bin/curl https://dv-g3b-emudhra.we-have-a-problem.com/
    /usr/bin/curl https://dv-g3b-aaa-emudhra.we-have-a-problem.com/

Run the `grep` again after each macOS update. An update can restore the file.
