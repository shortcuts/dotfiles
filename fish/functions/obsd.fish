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

    set -l repo (basename $repo_root)
    set -l abs (realpath $src)
    set -l rel (string replace "$repo_root/" "" $abs)

    set -l dest "$vault_path/$repo/$rel"
    mkdir -p (dirname "$dest")
    cp "$abs" "$dest"

    # Obsidian indexes new files with a small delay; retry until it sees the file.
    for i in (seq 6)
        if obsidian open vault=$vault path="$repo/$rel" 2>/dev/null
            return 0
        end
        sleep 0.5
    end
    echo "obsd: Obsidian could not open $repo/$rel" >&2
    return 1
end
