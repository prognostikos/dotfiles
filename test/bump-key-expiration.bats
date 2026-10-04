#!/usr/bin/env bats
# shellcheck shell=bash
# Bats sets status and output when run executes a command.
# shellcheck disable=SC2154

setup() {
  script="$BATS_TEST_DIRNAME/../bin/bump-key-expiration"
  export GNUPGHOME="$BATS_TEST_TMPDIR/gnupg"
  mkdir -m 700 "$GNUPGHOME"
  export REAL_GPG
  REAL_GPG="$(command -v gpg)"
  export CALL_LOG="$BATS_TEST_TMPDIR/calls"
  export CLIPBOARD="$BATS_TEST_TMPDIR/clipboard"
  export FAIL_SERVER=0
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/gpg" <<'SH'
#!/bin/bash
set -euo pipefail
if [[ "$1" == --keyserver ]]; then
  echo "$2" >>"$CALL_LOG"
  [[ "$2" == hkps://* ]] || exit 2
  if [[ "$FAIL_SERVER" == 1 && "$2" == hkps://keys.openpgp.org ]]; then
    echo 'gpg: keyserver send failed: No route to host' >&2
    exit 1
  fi
  exit 0
fi
exec "$REAL_GPG" --batch --pinentry-mode loopback --passphrase '' "$@"
SH
  cat >"$BATS_TEST_TMPDIR/bin/pbcopy" <<'SH'
#!/bin/bash
cat >"$CLIPBOARD"
SH
  chmod +x "$BATS_TEST_TMPDIR/bin/"*
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  old_time="$(( $(date +%s) - 259200 ))"
  gpg --faked-system-time "$old_time" --quick-generate-key 'Expiration Test <test@example.invalid>' ed25519 cert 1d
  fingerprint="$(gpg --with-colons --list-keys | awk -F: '$1 == "fpr" { print $10; exit }')"
}

teardown() {
  gpgconf --kill all
}

add_expired_subkey() {
  gpg --faked-system-time "$old_time" --quick-add-key "$fingerprint" cv25519 encr 1d
  listing="$(gpg --with-colons --list-keys)"
  [[ "$(awk -F: '$1 == "sub" { print $2 }' <<< "$listing")" == e ]]
}

check_export() {
  local listing
  listing="$(gpg --with-colons --show-keys "$CLIPBOARD")"
  awk -F: -v now="$(date +%s)" '
    $1 == "pub" || $1 == "sub" {
      count++
      if ($2 == "e" || $7 <= now) exit 1
    }
    END { if (!count) exit 1 }
  ' <<< "$listing"
}

function renews_expired_primary_and_subkey { #@test
  add_expired_subkey
  run "$script" "${fingerprint: -16}" 1y
  [[ "$status" == 0 ]]
  check_export
  [[ "$(wc -l <"$CALL_LOG")" == 2 ]]
}

function exports_and_tries_second_server_after_upload_failure { #@test
  add_expired_subkey
  export FAIL_SERVER=1
  run "$script" "$fingerprint"
  [[ "$status" == 1 ]]
  [[ "$output" == *'Retry with:'* ]]
  [[ "$output" == *'Public key copied to clipboard'* ]]
  [[ "$(wc -l <"$CALL_LOG")" == 2 ]]
  check_export
}

function supports_primary_key_without_subkeys { #@test
  run "$script" "$fingerprint" 6m
  [[ "$status" == 0 ]]
  check_export
}

function stops_before_upload_when_expiration_is_invalid { #@test
  run "$script" "$fingerprint" invalid-date
  [[ "$status" != 0 ]]
  [[ ! -e "$CALL_LOG" ]]
  [[ ! -e "$CLIPBOARD" ]]
}
