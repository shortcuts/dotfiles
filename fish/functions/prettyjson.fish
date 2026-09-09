function prettyjson --description 'Pretty print JSON; --save rewrites the file in place'
    argparse save -- $argv; or return

    if test (count $argv) -ne 1
        echo "usage: prettyjson [--save] file.json" >&2
        return 1
    end

    if not set -q _flag_save
        jq -C . $argv[1] | less -R
        return
    end

    # jq cannot read and write the same file in one pass
    set -l tmp (mktemp)
    if jq . $argv[1] >$tmp
        mv $tmp $argv[1]
    else
        rm -f $tmp
        return 1
    end
end
