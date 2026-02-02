git() {
  if [ -n "${RUNNING_IN_DEVCONTAINER:-}" ]; then
    if [ "$1" = "push" ]; then
      echo "Error: git $1 is disabled in devcontainer environments" >&2
      return 1
    fi
  fi

  command git "$@"
}
