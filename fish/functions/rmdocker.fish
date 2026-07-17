function rmdocker
    docker stop $(docker ps -a -q)
    docker builder prune -f
    docker system prune -a
end
