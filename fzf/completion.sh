# shellcheck shell=bash
# fzf shell integration - must be sourced after compinit
if command -v fzf > /dev/null 2>&1; then
  if fzf --zsh > /dev/null 2>&1; then
    source <(fzf --zsh)
  else
    # should be downloaded from github by script/setup
    source ~/.dotfiles/fzf/key-bindings.zsh
    source ~/.dotfiles/fzf/completion.zsh
  fi
fi
