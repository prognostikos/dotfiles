#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  sign_branch="$BATS_TEST_DIRNAME/../bin/git-sign-branch"
  test_dir="$BATS_TEST_TMPDIR"
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_TERMINAL_PROMPT=0
  export GIT_EDITOR=true
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE || true
  ssh-keygen -q -t ed25519 -N '' -f "$test_dir/key"
  printf 'test@example.com %s\n' "$(<"$test_dir/key.pub")" >"$test_dir/allowed-signers"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

new_repo() {
  git init -q -b main "$test_dir/$1"
  cd "$test_dir/$1" || return
  git config user.name Test
  git config user.email test@example.com
  git config commit.gpgSign false
  git config gpg.format ssh
  git config user.signingKey "$test_dir/key"
  git config gpg.ssh.allowedSignersFile "$test_dir/allowed-signers"
  git config rebase.updateRefs false
  git commit -q --allow-empty -m base
  base="$(git rev-parse HEAD)"
  git checkout -qb lower
  git commit -q --allow-empty -m lower
  lower="$(git rev-parse HEAD)"
  git checkout -qb middle
  git commit -q --allow-empty -m 'fixup! lower'
  middle="$(git rev-parse HEAD)"
  git checkout -qb top
  git commit -q --allow-empty -m top
  top="$(git rev-parse HEAD)"
}

run_sign() {
  "$sign_branch" "$@" >"$test_dir/output" 2>&1 || {
    cat "$test_dir/output" >&2
    fail "signing failed: $*"
  }
}

reject() {
  if "$sign_branch" "$@" >"$test_dir/output" 2>&1; then
    fail "accepted invalid input: $*"
  fi
  [[ "$(git rev-parse lower)" == "$lower" ]] || fail 'lower branch changed'
  [[ "$(git rev-parse middle)" == "$middle" ]] || fail 'middle branch changed'
  [[ "$(git rev-parse top)" == "$top" ]] || fail 'top branch changed'
}

check_signed_stack() {
  [[ "$(git rev-parse main)" == "$base" ]] || fail 'base changed'
  [[ "$(git rev-list --count main..top)" == 3 ]] || fail 'commits lost'
  [[ "$(git rev-parse top^)" == "$(git rev-parse middle)" ]] || fail 'middle ref is wrong'
  [[ "$(git rev-parse middle^)" == "$(git rev-parse lower)" ]] || fail 'lower ref is wrong'
  for ref in lower middle top; do
    git verify-commit "$ref" >/dev/null 2>&1 || fail "$ref is not signed"
  done
}

function signs_stack_and_updates_local_refs { #@test
  new_repo success
  git branch backup middle
  git update-ref refs/remotes/origin/lower "$lower"
  git update-ref refs/remotes/origin/middle "$middle"
  git update-ref refs/remotes/origin/top "$top"
  git config rebase.autoSquash true
  run_sign --stack main
  check_signed_stack
  [[ "$(git rev-parse backup)" == "$(git rev-parse middle)" ]] || fail 'backup ref was not updated'
  [[ "$(git rev-parse refs/remotes/origin/lower)" == "$lower" ]] || fail 'remote ref changed'
  [[ "$(git config rebase.updateRefs)" == false ]] || fail 'config changed'
  run_sign --stack main
  check_signed_stack
}

function rejects_invalid_stack_inputs { #@test
  new_repo preflight
  reject --stack
  reject --stack main top
  reject --stack --all main
  reject --all --stack main
  reject --stack absent
  git branch unrelated "$base"
  git checkout -q unrelated
  git commit -q --allow-empty -m unrelated
  git checkout -q top
  reject --stack unrelated
  git checkout -q --detach
  reject --stack main
  git checkout -q top
  git worktree add -q "$test_dir/lower-worktree" lower
  reject --stack main
  grep -q 'another worktree' "$test_dir/output" || fail 'missing worktree error'
  git worktree remove "$test_dir/lower-worktree"
  printf 'tracked\n' >file
  git add file
  reject --stack main
  git reset -q -- file
  git update-ref refs/remotes/origin/missing "$middle"
  reject --stack main
  grep -q 'No local stack branch' "$test_dir/output" || fail 'missing local branch error'
  git branch missing "$middle"
  run_sign --stack main
  check_signed_stack
}

function accepts_a_renamed_tracking_branch { #@test
  new_repo renamed
  git update-ref refs/remotes/origin/remote-lower "$lower"
  git config branch.lower.remote origin
  git config branch.lower.merge refs/heads/remote-lower
  git config remote.origin.url "$test_dir/unused"
  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  run_sign --stack main
  check_signed_stack
}

function keeps_rebase_state_for_abort_and_continue { #@test
  new_repo failure
  # Fail after the first successful amend, with intermediate updates pending.
  printf '%s\n' '#!/bin/sh' 'git config user.signingKey /no/such/signing-key' >.git/hooks/post-commit
  chmod +x .git/hooks/post-commit
  reject --stack main
  [[ -d .git/rebase-merge ]] || fail 'rebase state was removed'
  grep -q 'git rebase --continue' "$test_dir/output" || fail 'missing recovery message'
  reject --stack main
  git rebase --abort >"$test_dir/output" 2>&1
  [[ "$(git rev-parse HEAD)" == "$top" ]] || fail 'abort did not restore HEAD'
  [[ "$(git rev-parse lower)" == "$lower" ]] || fail 'abort changed lower'
  git config core.hooksPath "$test_dir/no-hooks"
  reject --stack main
  git config user.signingKey "$test_dir/key"
  git rebase --continue >"$test_dir/output" 2>&1 || {
    cat "$test_dir/output" >&2
    fail 'cannot continue signing'
  }
  check_signed_stack
}

function preserves_merge_topology_and_signatures { #@test
  new_repo merges
  git checkout -qb side lower
  printf 'side\n' >side-file
  git add side-file
  git commit -q -m side
  git checkout -q top
  printf 'top\n' >top-file
  git add top-file
  git commit -q -m content
  git merge -q --no-ff side -m merge
  original_tree="$(git rev-parse 'HEAD^{tree}')"
  original_count="$(git rev-list --count main..HEAD)"
  run_sign --stack main
  [[ "$(git rev-parse 'HEAD^{tree}')" == "$original_tree" ]] || fail 'merge tree changed'
  [[ "$(git rev-list --count main..HEAD)" == "$original_count" ]] || fail 'merge commits lost'
  [[ "$(git rev-list --count --merges main..HEAD)" == 1 ]] || fail 'merge was flattened'
  [[ "$(git rev-parse HEAD^2)" == "$(git rev-parse side)" ]] || fail 'side ref is wrong'
  while read -r commit; do
    git verify-commit "$commit" >/dev/null 2>&1 || fail 'unsigned commit in merged stack'
  done < <(git rev-list main..HEAD)
}

function all_mode_keeps_intermediate_refs { #@test
  new_repo all-mode
  git config rebase.updateRefs true
  run_sign --all
  [[ "$(git rev-parse lower)" == "$lower" ]] || fail '--all moved lower'
  [[ "$(git rev-parse middle)" == "$middle" ]] || fail '--all moved middle'
  git verify-commit top >/dev/null 2>&1 || fail '--all did not sign top'
}

function signs_another_branch_in_a_temporary_worktree { #@test
  new_repo other-branch
  git checkout -q main
  git config rebase.updateRefs true
  run_sign --all top
  [[ "$(git rev-parse HEAD)" == "$base" ]] || fail 'temporary worktree changed current HEAD'
  [[ "$(git rev-parse lower)" == "$lower" ]] || fail 'temporary worktree moved lower'
  git verify-commit top >/dev/null 2>&1 || fail 'temporary worktree did not sign top'
}

function signs_an_ordinary_range { #@test
  new_repo range-mode
  printf 'content\n' >file
  git add file
  git commit -q --amend --no-edit
  run_sign middle
  git verify-commit top >/dev/null 2>&1 || fail 'range mode did not sign top'
  [[ "$(git rev-parse middle)" == "$middle" ]] || fail 'range mode changed base'
}
