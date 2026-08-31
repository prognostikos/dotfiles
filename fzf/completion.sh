# shellcheck shell=bash
# fzf shell integration - must be sourced after compinit
if command -v fzf > /dev/null 2>&1; then
  if fzf --zsh > /dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh && -r /usr/share/doc/fzf/examples/completion.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    source /usr/share/doc/fzf/examples/completion.zsh
  else
    fzf_version=$(fzf --version | cut -d " " -f 1)
    fzf_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fzf/$fzf_version"

    if [[ -r "$fzf_cache_dir/key-bindings.zsh" && -r "$fzf_cache_dir/completion.zsh" ]]; then
      source "$fzf_cache_dir/key-bindings.zsh"
      source "$fzf_cache_dir/completion.zsh"
    fi

    unset fzf_cache_dir fzf_version
  fi

  if (( ${+widgets[fzf-history-widget]} )); then
    bindkey '^P' fzf-history-widget
  fi
fi
