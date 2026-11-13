#!/usr/bin/env bats
# shellcheck shell=bash
# shellcheck disable=SC2154

setup() {
  repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  fixture_root="$BATS_TEST_TMPDIR/dotfiles with spaces"
  destination="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fixture_root/agents.symlink/skills/simplify" "$fixture_root/claude.symlink" "$destination"
  ln -s agents.symlink "$fixture_root/.agents"
  printf 'Shared skill\n' > "$fixture_root/agents.symlink/skills/simplify/SKILL.md"
  printf 'Claude settings\n' > "$fixture_root/claude.symlink/settings.json"
  # Disable optional tool installation.
  # shellcheck disable=SC2317
  fzf() { return 0; }
  # shellcheck disable=SC2317
  nvim() { return 0; }
  export -f fzf nvim
  cd "$fixture_root" || return
}

function repository_has_the_agents_link_that_host_skill_links_need { #@test
  [ "$(readlink "$repo_root/.agents")" = agents.symlink ]
}

function host_setup_links_claude_and_shared_skills_and_can_run_twice { #@test
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(readlink "$destination/.claude")" = "$fixture_root/claude.symlink" ]
  [ "$(cat "$destination/.claude/settings.json")" = 'Claude settings' ]
  [ "$(readlink "$destination/.claude/skills/simplify")" = '../../.agents/skills/simplify' ]
  [ "$(cat "$destination/.claude/skills/simplify/SKILL.md")" = 'Shared skill' ]
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [[ "$output" != *simplify* ]]
}

function setup_preserves_existing_claude_skills { #@test
  mkdir -p "$fixture_root/claude.symlink/skills/simplify"
  printf 'Existing skill\n' > "$fixture_root/claude.symlink/skills/simplify/SKILL.md"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(cat "$destination/.claude/skills/simplify/SKILL.md")" = 'Existing skill' ]
  [[ "$output" == *'Skipping shared skill simplify'* ]]
}

function container_setup_uses_the_mounted_directories { #@test
  # The container mounts the directories that the host links resolve to.
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  container_home="$BATS_TEST_TMPDIR/container-home"
  mkdir -p "$container_home"
  cp -R "$fixture_root/agents.symlink" "$container_home/.agents"
  cp -R "$fixture_root/claude.symlink" "$container_home/.claude"
  printf 'Host state\n' > "$container_home/.claude/history.jsonl"

<<<<<<< Updated upstream
  # The container has its own clone of the repository.
||||||| Stash base
function container_skill_links_work_at_another_home_path { #@test
  # Real directories represent the mounted .agents and .claude directories.
  cp -R "$fixture_root/agents.symlink" "$destination/.agents"
  mkdir -p "$destination/.claude"
  # Treat .agents as a mount so setup must use its existing contents.
  # shellcheck disable=SC2317
  mountpoint() { [[ "$2" == */.agents ]]; }
  export -f mountpoint
  run env RUNNING_IN_DEVCONTAINER=1 bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  relocated="$BATS_TEST_TMPDIR/container-home"
  mv "$destination" "$relocated"
  [ -f "$relocated/.claude/skills/simplify/SKILL.md" ]
  [ ! -e "$relocated/.claude/settings.json" ]
}

function host_skills_survive_container_setup_without_the_host_repo { #@test
  mkdir -p "$fixture_root/claude.symlink/skills/claude-only"
  printf 'Claude-only skill\n' > "$fixture_root/claude.symlink/skills/claude-only/SKILL.md"
  ln -s ../../.agents/skills/simplify "$fixture_root/claude.symlink/skills/simplify"
  mkdir -p "$destination/.claude"
  ln -s "$fixture_root/claude.symlink/skills" "$destination/.claude/skills"

  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ ! -L "$destination/.claude/skills" ]
  [ "$(cat "$destination/.claude/skills/claude-only/SKILL.md")" = 'Claude-only skill' ]
  printf 'Local edit\n' > "$destination/.claude/skills/claude-only/SKILL.md"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(cat "$destination/.claude/skills/claude-only/SKILL.md")" = 'Local edit' ]
  [ "$(cat "$fixture_root/claude.symlink/skills/claude-only/SKILL.md")" = 'Claude-only skill' ]

  # Copy the resolved bind sources, then remove the host repository. This
  # models the container's mounts without making host paths accessible.
  relocated="$BATS_TEST_TMPDIR/container-home"
  mkdir -p "$relocated"
  cp -R "$destination/.claude" "$relocated/.claude"
  cp -R "$destination/.agents/." "$relocated/.agents"
=======
function claude_links_are_relative_to_home_and_replace_container_paths { #@test
  home_repo="$destination/.dotfiles"
  mv "$fixture_root" "$home_repo"
  cd "$home_repo" || return
  mkdir -p "$destination/.claude"
  ln -s /home/dev/.dotfiles/claude.symlink/settings.json "$destination/.claude/settings.json"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(readlink "$destination/.claude/settings.json")" = '../.dotfiles/claude.symlink/settings.json' ]
  relocated="$BATS_TEST_TMPDIR/container-home"
  mv "$destination" "$relocated"
  [ "$(cat "$relocated/.claude/settings.json")" = 'Claude settings' ]
}

function setup_keeps_real_files_in_claude_directory { #@test
  mkdir -p "$destination/.claude"
  printf 'Live settings\n' > "$destination/.claude/settings.json"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ ! -L "$destination/.claude/settings.json" ]
  [ "$(cat "$destination/.claude/settings.json")" = 'Live settings' ]
  [ ! -e "$destination/.claude/settings.json.backup" ]
}

function container_skill_links_work_at_another_home_path { #@test
  # Real directories represent the mounted .agents and .claude directories.
  cp -R "$fixture_root/agents.symlink" "$destination/.agents"
  mkdir -p "$destination/.claude"
  # Treat .agents as a mount so setup must use its existing contents.
  # shellcheck disable=SC2317
  mountpoint() { [[ "$2" == */.agents ]]; }
  export -f mountpoint
  run env RUNNING_IN_DEVCONTAINER=1 bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  relocated="$BATS_TEST_TMPDIR/container-home"
  mv "$destination" "$relocated"
  [ -f "$relocated/.claude/skills/simplify/SKILL.md" ]
  [ ! -e "$relocated/.claude/settings.json" ]
}

function host_skills_survive_container_setup_without_the_host_repo { #@test
  mkdir -p "$fixture_root/claude.symlink/skills/claude-only"
  printf 'Claude-only skill\n' > "$fixture_root/claude.symlink/skills/claude-only/SKILL.md"
  ln -s ../../.agents/skills/simplify "$fixture_root/claude.symlink/skills/simplify"
  mkdir -p "$destination/.claude"
  ln -s "$fixture_root/claude.symlink/skills" "$destination/.claude/skills"

  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ ! -L "$destination/.claude/skills" ]
  [ "$(cat "$destination/.claude/skills/claude-only/SKILL.md")" = 'Claude-only skill' ]
  printf 'Local edit\n' > "$destination/.claude/skills/claude-only/SKILL.md"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(cat "$destination/.claude/skills/claude-only/SKILL.md")" = 'Local edit' ]
  [ "$(cat "$fixture_root/claude.symlink/skills/claude-only/SKILL.md")" = 'Claude-only skill' ]

  # Copy the resolved bind sources, then remove the host repository. This
  # models the container's mounts without making host paths accessible.
  relocated="$BATS_TEST_TMPDIR/container-home"
  mkdir -p "$relocated"
  cp -R "$destination/.claude" "$relocated/.claude"
  cp -R "$destination/.agents/." "$relocated/.agents"
>>>>>>> Stashed changes
  container_repo="$BATS_TEST_TMPDIR/container-dotfiles"
  mv "$fixture_root" "$container_repo"
  cd "$container_repo" || return
  printf 'Clone settings\n' > "$container_repo/claude.symlink/settings.json"
  # shellcheck disable=SC2317
  mountpoint() { [[ "$2" == */.agents || "$2" == */.claude ]]; }
  export -f mountpoint

  run bash "$repo_root/script/setup" "$container_home"
  [ "$status" -eq 0 ]
  [ ! -L "$container_home/.claude" ]
  [ ! -L "$container_home/.claude/settings.json" ]
  [ "$(cat "$container_home/.claude/settings.json")" = 'Claude settings' ]
  [ "$(cat "$container_home/.claude/history.jsonl")" = 'Host state' ]
  [ "$(cat "$container_home/.claude/skills/simplify/SKILL.md")" = 'Shared skill' ]
}

function container_setup_adds_links_for_new_shared_skills { #@test
  mkdir -p "$destination/.agents/skills/simplify" "$destination/.claude"
  printf 'Mounted skill\n' > "$destination/.agents/skills/simplify/SKILL.md"
  # shellcheck disable=SC2317
  mountpoint() { [[ "$2" == */.agents || "$2" == */.claude ]]; }
  export -f mountpoint
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(readlink "$destination/.claude/skills/simplify")" = '../../.agents/skills/simplify' ]
  [ "$(cat "$destination/.claude/skills/simplify/SKILL.md")" = 'Mounted skill' ]
  [ ! -e "$destination/.claude/settings.json" ]
}
