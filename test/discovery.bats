#!/usr/bin/env bats
# shellcheck shell=bash
# Bats assigns status and output in run.
# shellcheck disable=SC2154

setup() {
  repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  fixture_root="$BATS_TEST_TMPDIR/dotfiles with spaces"
  mkdir -p "$fixture_root/topic" "$fixture_root/test/nested"
}

function setup_excludes_test_symlinks { #@test
  local destination="$BATS_TEST_TMPDIR/destination"
  mkdir -p "$destination"
  touch "$fixture_root/topic/normal.symlink"
  touch "$fixture_root/test/fixture.symlink"
  mkdir -p "$fixture_root/test/directory.symlink"
  touch "$fixture_root/test/nested/deep.symlink"

  # Disable optional tool installation in this test.
  # These exported functions run in the setup subprocess.
  # shellcheck disable=SC2317
  fzf() { return 0; }
  # shellcheck disable=SC2317
  nvim() { return 0; }
  export -f fzf nvim
  cd "$fixture_root" || return
  run bash "$repo_root/script/setup" "$destination"
  [ "$status" -eq 0 ]
  [ -L "$destination/.normal" ]
  [ "$(readlink "$destination/.normal")" = "$fixture_root/topic/normal.symlink" ]
  [ ! -e "$destination/.fixture" ]
  [ ! -L "$destination/.fixture" ]
  [ ! -e "$destination/.directory" ]
  [ ! -L "$destination/.directory" ]
  [ ! -e "$destination/.deep" ]
  [ ! -L "$destination/.deep" ]
}

function bash_excludes_test_aliases { #@test
  local loader
  printf 'echo normal\n' >"$fixture_root/topic/aliases"
  printf 'echo test-file-loaded\n' >"$fixture_root/test/aliases"
  # Exercise the real discovery loop without the rest of shell startup.
  loader="$(sed -n '/^for aliases_file /,/^done/p' "$repo_root/bash/bashrc.symlink")"
  [ -n "$loader" ]
  run env DOTFILES_ROOT="$fixture_root" bash --noprofile --norc -c "$loader"
  [ "$status" -eq 0 ]
  [ "$output" = normal ]
}

function zsh_excludes_all_test_shell_files { #@test
  local loader variable file
  for file in config.zsh aliases completion.sh; do
    printf 'echo normal\n' >"$fixture_root/topic/$file"
    printf 'echo test-file-loaded\n' >"$fixture_root/test/$file"
    printf 'echo nested-test-file-loaded\n' >"$fixture_root/test/nested/$file"
  done
  for variable in config_file aliases_file completion_file; do
    loader="$(sed -n "/^for $variable /,/^done/p" "$repo_root/zsh/zshrc.symlink")"
    [ -n "$loader" ]
    run env ZSH="$fixture_root" zsh -f -c "$loader"
    [ "$status" -eq 0 ]
    [ "$output" = normal ]
  done
}
