function gsq
    argparse 'b/base=' -- $argv
    or return 1
    set base (set -q _flag_base && echo $_flag_base || echo main)
    set msg $argv[1]
    set merge_base (git merge-base HEAD $base)
    if test -z "$merge_base"
        echo "Error: No common ancestor found with $base"
        return 1
    end
    set count (git rev-list --count "$merge_base"..HEAD)
    echo "Squashing $count commits against $base..."
    if test -n "$msg"
        git reset --soft $merge_base && git commit -m "$msg"
    else
        git reset --soft $merge_base && git commit
    end
end
