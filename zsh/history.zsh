alias history="history 1"
HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
HISTSIZE=99999                 # lines of history to maintain memory
SAVEHIST=99999                 # lines of history to maintain in history file.
HISTFILESIZE=99999
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY           # import new commands from history file & append
