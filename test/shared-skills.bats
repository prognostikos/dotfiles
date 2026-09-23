#!/usr/bin/env bats
# shellcheck shell=bash
# shellcheck disable=SC2154

setup() {
  repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  fixture_root="$BATS_TEST_TMPDIR/dotfiles with spaces"
  destination="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fixture_root/agents.symlink/skills/simplify" "$fixture_root/claude.symlink" "$destination"
  printf 'Shared skill\n' > "$fixture_root/agents.symlink/skills/simplify/SKILL.md"
  printf 'Claude settings\n' > "$fixture_root/claude.symlink/settings.json"
  # Disable optional tool installation.
  # shellcheck disable=SC2317
  fzf() { return 0; }
  # shellcheck disable=SC2317
  nvim() { return 0; }
  export -f fzf nvim
  unset RUNNING_IN_DEVCONTAINER
  cd "$fixture_root" || return
}

function setup_links_shared_skills_and_can_run_twice { #@test
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ -d "$destination/.claude/skills" ]
  [ ! -L "$destination/.claude" ]
  [ "$destination/.claude/skills/simplify/SKILL.md" -ef "$fixture_root/agents.symlink/skills/simplify/SKILL.md" ]
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(readlink "$destination/.claude/skills/simplify")" = '../../.agents/skills/simplify' ]
}

function setup_preserves_existing_claude_skills { #@test
  mkdir -p "$destination/.claude/skills/simplify"
  printf 'Existing skill\n' > "$destination/.claude/skills/simplify/SKILL.md"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ "$(cat "$destination/.claude/skills/simplify/SKILL.md")" = 'Existing skill' ]
  [[ "$output" == *'Skipping shared skill simplify'* ]]
}

function setup_converts_managed_claude_symlink_without_losing_settings { #@test
  ln -s "$fixture_root/claude.symlink" "$destination/.claude"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ ! -L "$destination/.claude" ]
  [ "$destination/.claude/settings.json" -ef "$fixture_root/claude.symlink/settings.json" ]
  [ -f "$destination/.claude/skills/simplify/SKILL.md" ]
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
  container_repo="$BATS_TEST_TMPDIR/container-dotfiles"
  mv "$fixture_root" "$container_repo"
  cd "$container_repo" || return
  # shellcheck disable=SC2317
  mountpoint() { [[ "$2" == */.agents ]]; }
  export -f mountpoint
  run env RUNNING_IN_DEVCONTAINER=1 bash "$repo_root/script/setup" "$relocated"
  [ "$status" -eq 0 ]
  [ -f "$relocated/.claude/skills/simplify/SKILL.md" ]
  [ "$(cat "$relocated/.claude/skills/claude-only/SKILL.md")" = 'Local edit' ]
}

function fresh_host_setup_copies_claude_skills_into_a_real_directory { #@test
  mkdir -p "$fixture_root/claude.symlink/skills/claude-only"
  printf 'Claude-only skill\n' > "$fixture_root/claude.symlink/skills/claude-only/SKILL.md"
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ ! -L "$destination/.claude/skills" ]
  [ ! -L "$destination/.claude/skills/claude-only" ]
  [ -f "$destination/.claude/skills/simplify/SKILL.md" ]
  [ "$(cat "$destination/.claude/skills/claude-only/SKILL.md")" = 'Claude-only skill' ]
}

function container_reports_broken_host_skills_link_without_changing_it { #@test
  mkdir -p "$destination/.claude"
  ln -s /missing-host/dotfiles/claude.symlink/skills "$destination/.claude/skills"
  run env RUNNING_IN_DEVCONTAINER=1 bash "$repo_root/script/setup" "$destination"
  [ "$status" -ne 0 ]
  [[ "$output" == *'Run the updated script/setup on the host'* ]]
  [ "$(readlink "$destination/.claude/skills")" = /missing-host/dotfiles/claude.symlink/skills ]
}
