function gb
    # git for-each-ref \
    #     --sort=committerdate refs/heads/ \
    #     --format="%(HEAD) [%(color:green)%(committerdate:relative)%(color:reset)] (%(color:red)%(objectname:short)%(color:reset)) %(color:yellow)%(refname:short)%(color:reset): %(contents:subject) %(color:brightblack)(by %(authorname))%(color:reset)"
    #
    #
    set -l lines (git for-each-ref \
        --sort=-committerdate refs/heads \
        --format='%(refname:short)|%(HEAD)%(color:yellow)%(refname:short)|%(color:bold green)%(committerdate:relative)|%(color:blue)%(subject)|%(color:magenta)%(authorname)%(color:reset)' \
        --color=always)

    for line in $lines
        set -l branch (echo "$line" | awk 'BEGIN { FS = "|" }; { print $1 }' | tr -d '*')
        set -l ahead (git rev-list --count "$refbranch:-origin/main}..$branch")
        # set -l behind (git rev-list --count \"$branch..$refbranch:-origin/master\")
        # set -l colorline (echo \"$line\" | sed 's/^[^|]*|//')

        # echo "$ahead|$behind|$colorline" | awk -F'|' -vOFS='|' '{$5=substr($5,1,70)}1'
    end

            #
            #
            # | while read line; do \
            #     set -l branch (echo \"$line\" | awk 'BEGIN { FS = \"|\" }; { print $1 }' | tr -d '*')
            #     set -l ahead (git rev-list --count \"${refbranch:-origin/master}..${branch}\")
            #     set -l behind (git rev-list --count \"${branch}..${refbranch:-origin/master}\")
            #
            #     colorline=(echo \"$line\" | sed 's/^[^|]*|//'); \
            #     echo \"$ahead|$behind|$colorline\" | awk -F'|' -vOFS='|' '{$5=substr($5,1,70)}1'; 
            # done \
            # | (echo \"ahead|behind||branch|lastcommit|message|author\\n\" && cat) | column -ts'|';
end
