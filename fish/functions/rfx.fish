function rfx --description "rainfrog on a postgres service of the current kube context"
    set -l ctx (kubectl config current-context); or return
    # pq-conn-string.sh reads the indexing-admin-password, so default to the indexing DB
    set -l svc postgres-db-indexing
    set -q argv[1]; and set svc $argv[1]

    set -l user algolia
    set -l pass algolia
    set -l db metis
    set -l ssl
    switch $ctx
        case 'm*-*'
            # the kube context name is the metis instance name (e.g. m1351-eu)
            set -l conn (~/Documents/metis/tools/pq-conn-string.sh $ctx); or return
            set user (string match -r "user='([^']*)'" -- $conn)[2]
            set pass (string match -r "password='([^']*)'" -- $conn)[2]
            set db (string match -r "dbname='([^']*)'" -- $conn)[2]
            set ssl --ssl-required
        case k3d-minimetis
        case '*'
            echo "rfx: $ctx is not a metis instance" >&2
            return 1
    end

    set -l port (random 20000 40000)
    kubectl --context $ctx -n default port-forward svc/$svc $port:5432 >/dev/null &
    set -l pf $last_pid
    # rainfrog fails at once if the forward is not up yet
    while not nc -z localhost $port
        sleep 0.2
    end
    rainfrog --driver postgres --host localhost --port $port --database $db --username $user --password $pass $ssl
    kill $pf
end
