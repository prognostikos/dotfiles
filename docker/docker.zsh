docker-cleanup() {
  docker ps -a | grep Exit | awk '{print $1}' | xargs docker rm
}

docker-cleanupi() {
  docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi
}

docker-vars() {
  while IFS='' read -r line || [[ -n $line ]]; do
      [[ $line == '#'* ]] || echo -n "-e $line "
  done < "$1"
}
