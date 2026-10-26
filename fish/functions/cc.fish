# Two Claude accounts, one config. Keychain keys each login by CLAUDE_CONFIG_DIR, so a
# separate dir per account keeps both logins; every other file links back to ~/.claude.
function cc --description 'cc setup | cc a|b [claude args]'
    set -l shared (path resolve ~/.claude)
    # Per-account state: login/MCP file and runtime locks must not be shared.
    set -l skip .claude.json .credentials.json sessions daemon.lock daemon.status.json daemon-auth-cooldown daemon-auth-status.json

    switch $argv[1]
        case setup
            for acct in a b
                set -l dir ~/.claude-$acct
                mkdir -p $dir
                for name in (command ls -A $shared)
                    set -l src $shared/$name
                    contains -- $name $skip; and continue
                    test -e $dir/$name -o -L $dir/$name; or ln -s $src $dir/$name
                end
                # Carry over MCP servers, project trust and UI state. The account's own keys win.
                if test -e ~/.claude.json; and command -q jq
                    if test -e $dir/.claude.json
                        jq -s '(.[0] | del(.oauthAccount, .userID)) * .[1]' ~/.claude.json $dir/.claude.json >$dir/.claude.json.new
                    else
                        jq 'del(.oauthAccount, .userID)' ~/.claude.json >$dir/.claude.json.new
                    end
                    and mv $dir/.claude.json.new $dir/.claude.json
                end
            end
            echo "next: cc a, then /login (account 1). cc b, then /login (account 2)."
        case a b
            CLAUDE_CONFIG_DIR=$HOME/.claude-$argv[1] command claude $argv[2..-1]
        case '*'
            echo "usage: cc setup | cc a|b [claude args]" >&2
            return 1
    end
end
