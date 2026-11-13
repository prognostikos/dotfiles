#!/usr/bin/env bats
# shellcheck shell=bash
# Bats sets status and output when run executes a command.
# shellcheck disable=SC2154

setup() {
  helper="$BATS_TEST_DIRNAME/../bin/.worktree-layout"
  config_helper="$BATS_TEST_DIRNAME/../bin/.devcontainer-config"
  parent="$BATS_TEST_TMPDIR/workspace"
  project="$parent/project"
  mkdir -p "$project/.devcontainer"
  git init -q "$parent"
  git init -q "$project"
  printf '{}\n' > "$project/.devcontainer/devcontainer.json"
  project="$(CDPATH='' cd "$project" && pwd -P)"
}

@test "workspace resolution ignores CDPATH and selects the project configuration" {
  # shellcheck disable=SC2016
  run env CDPATH="$parent" bash -c '
    set -euo pipefail
    source "$1"
    source "$2"
    cd "$3"
    wt_resolve_current_worktree
    devcontainer_resolve_workspace "$WT_MAIN_WORKTREE"
    printf "%s\n" "$WT_MAIN_WORKTREE" "$WT_CURRENT_WORKTREE" \
      "$DEVCONTAINER_CONFIG_FILE" "${DEVCONTAINER_WORKSPACE_ARGS[@]}"
  ' bash "$helper" "$config_helper" "$project"

  [ "$status" -eq 0 ]
  [ "$output" = "$project
$project
$project/.devcontainer/devcontainer.json
--workspace-folder
$project" ]
}
