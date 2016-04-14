docker-cleanup() {
  docker ps -a | grep Exit | awk '{print $1}' | xargs docker rm
}

docker-cleanupi() {
  docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi
}

docker-ip() {
  docker inspect --format '{{ .NetworkSettings.IPAddress }}'
}

docker-kill() {
  docker kill $(docker ps -q)
}

docker-vars() {
  while IFS='' read -r line || [[ -n $line ]]; do
    [[ $line == '#'* ]] || echo -n "-e $line "
  done < "$1"
}

# Normally docker is aliased to this, for now it's disabled with new Docker.app
docker-env() {
  if [[ -z "$DOCKER_HOST" ]]; then
    eval $(docker-machine env dockerhost)
  fi
  \docker $@
}
