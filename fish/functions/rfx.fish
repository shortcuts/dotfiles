function rfx --description "rainfrog on a postgres service of the current kube context"
    set -l ctx (kubectl config current-context); or return
    # instances only have proxy pods (psql-search-proxy -> search, the plain psql-proxy -> indexing)
    set -l kinds (kubectl --context $ctx -n metis get pods -o jsonpath='{range .items[*]}{.metadata.labels.app\.kubernetes\.io/name}{"\n"}{end}' 2>/dev/null | string match -r '^psql-.*proxy$' | string replace -r '^psql-(.+)-proxy$' '$1' | string replace psql-proxy indexing | sort -u)
    # k3d has plain services: postgres-db-search-deployer -> search-deployer
    set -q kinds[1]; or set kinds (kubectl --context $ctx get svc -o name | string match -rg '^service/postgres-db-(.+)')
    set argv (string replace postgres-db- '' -- $argv)
    if contains -- "$argv[1]" -h --help
        echo "usage: rfx [KIND]"
        echo "kinds in $ctx (first is the default):"
        printf '  %s\n' $kinds
        return
    end
    set -l kind $kinds[1]
    set -q argv[1]; and set kind $argv[1]
    if not contains -- "$kind" $kinds
        echo "rfx: no postgres-db-$kind service in $ctx, available: $kinds" >&2
        return 1
    end
    set -l svc postgres-db-$kind

    # instances expose each database only through a proxy pod, the plain one serves the unnamed kind
    set -l pod
    for name in psql-$kind-proxy psql-proxy
        set pod (kubectl --context $ctx -n metis get pods -l app.kubernetes.io/name=$name -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        test -n "$pod"; and break
    end

    set -l user algolia
    set -l pass algolia
    set -l db metis
    set -l ssl
    set -l ns default
    set -l target svc/$svc
    if test -n "$pod"
        # the kube context name is the metis instance name (e.g. m1351-eu)
        set -l conn (~/Documents/metis/tools/pq-conn-string.sh -v $kind-admin-password $ctx); or return
        set user (string match -r "user='([^']*)'" -- $conn)[2]
        set pass (string match -r "password='([^']*)'" -- $conn)[2]
        set db (string match -r "dbname='([^']*)'" -- $conn)[2]
        # pq-conn-string.sh exits 0 even when vault read fails
        if test -z "$pass"
            echo "rfx: no password from vault for $ctx" >&2
            return 1
        end
        string match -q '*sslmode=require*' -- $conn; and set ssl --ssl-required
        set ns metis
        set target pod/$pod
    end

    set -l port (random 20000 40000)
    kubectl --context $ctx -n $ns port-forward $target $port:5432 >/dev/null &
    set -l pf $last_pid
    # rainfrog fails at once if the forward is not up yet
    while not nc -z localhost $port
        kill -0 $pf 2>/dev/null; or return 1
        sleep 0.2
    end
    rainfrog --driver postgres --host localhost --port $port --database $db --username $user --password $pass $ssl
    kill $pf
end
