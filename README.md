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

    make install mac     # or: make install linux

Without the argument, `install.sh` picks the platform from `uname`.
The Mac mini server steps are in [LINUX.md](LINUX.md).

## update all

    make update mac      # or: make update linux

## move untracked files to a new Mac

Use this for files that must not go to git: `~/.ssh`, `.netrc`, `.vault-token`,
`~/Documents` notes and photos. Both Macs must be on the same network.

1. On the new Mac, open System Settings → General → Sharing and enable Remote Login.
2. Note its name: `scutil --get LocalHostName` prints `<name>`, reachable as `<name>.local`.
3. On this Mac, copy with `rsync`. The trailing `/` on the source matters:

       rsync -avhP --dry-run ~/Documents/anko/ <user>@<name>.local:Documents/anko/

   Remove `--dry-run` once the file list looks right. Repeat per directory.
4. Fix key permissions on the new Mac: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*`.
5. Disable Remote Login again when the copy ends.

For one file, AirDrop is faster. For the whole user account, use Migration Assistant over
a Thunderbolt cable. A work laptop's MDM may block it, so prefer `rsync`.

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
