function obsd --description "Copy a file into the Obsidian vault under the current repo folder and open it"
    if test (count $argv) -eq 0
        echo "usage: obsd <path-to-file>" >&2
        return 1
    end

    set -l vault notes
    set -l vault_path "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"

    set -l src $argv[1]
    if not test -f "$src"
        echo "obsd: file not found: $src" >&2
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "obsd: not inside a git repository" >&2
        return 1
    end

    set -l abs (realpath $src)
    # Without this guard `string replace` is a no-op and the absolute path leaks into the vault.
    if not string match -q "$repo_root/*" -- $abs
        echo "obsd: $abs is outside the repo $repo_root" >&2
        return 1
    end

    # Obsidian skips dot-folders, so "~/.config" becomes "config" in the vault.
    set -l repo (basename $repo_root | string replace -r '^\.' '')
    # The vault keeps ".claude/notes/x.md" at "<repo>/notes/x.md".
    set -l rel (string replace "$repo_root/" "" $abs | string replace -r '^\.claude/' '' | string replace -ar '(^|/)\.' '$1')

    # Work repos live under "30 Work", the rest under "10 Projects".
    set -l area "10 Projects"
    if test -d "$vault_path/30 Work/$repo"
        set area "30 Work"
    end
    set -l vault_rel "$area/$repo/$rel"
    # The metis-investigate skill writes from the dotfiles repo, but the notes belong to the metis project.
    if string match -q ".claude/.metis-investigate/*" -- (string replace "$repo_root/" "" $abs)
        set vault_rel "30 Work/metis/notes/"(basename $abs)
    end

    set -l dest "$vault_path/$vault_rel"
    mkdir -p (dirname "$dest")
    cp "$abs" "$dest"

    # Obsidian indexes new files with a small delay; retry until it sees the file.
    for i in (seq 6)
        # `obsidian open` exits 0 on "not found", so match its output instead.
        set -l out (obsidian open vault=$vault path="$vault_rel" 2>&1)
        if string match -q "Opened:*" -- $out
            return 0
        end
        sleep 0.5
    end
    echo "obsd: Obsidian could not open $vault_rel" >&2
    return 1
end
