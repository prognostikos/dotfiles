#!/bin/bash
set -euo pipefail

config_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# Homebrew tools may not be in the Rex server's PATH.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
command -v nvim >/dev/null
snapshot="$(mktemp "${TMPDIR:-/tmp}/rex-copy.XXXXXX")"
trap 'rm -f "$snapshot"' EXIT
rex capture --session "$1" --block "$2" --trim --unwrap > "$snapshot"
nvim -u "$config_dir/copy-mode.lua" -i NONE -n -R -- "$snapshot"
