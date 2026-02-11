# shellcheck shell=bash
# fzf shell integration - must be sourced after compinit
if command -v fzf > /dev/null 2>&1; then
  if fzf --zsh > /dev/null 2>&1; then
    source <(fzf --zsh)
  else
    # should be downloaded from github by script/setup
    source "$ZSH/fzf/key-bindings.zsh"
    source "$ZSH/fzf/completion.zsh"
  fi
  bindkey '^P' fzf-history-widget
fi
