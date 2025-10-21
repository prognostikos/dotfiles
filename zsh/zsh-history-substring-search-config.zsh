#-----------------------------------------------------------------------------
# shortcut key bindings
#-----------------------------------------------------------------------------

# bind P and N for EMACS mode
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# bind k and j for VI mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# bind up and down arrow keys
for keycode in '[' '0'; do
  bindkey "^[${keycode}A" history-substring-search-up
  bindkey "^[${keycode}B" history-substring-search-down
done
unset keycode

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=black,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=black,bold'
