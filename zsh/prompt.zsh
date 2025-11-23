local hostname="%m:"
local username=''

[ -z $SSH_TTY ] && hostname=''
[ "$USER" != rohrer ] && username="%n@"

# Configure vcs_info for git prompt
autoload -Uz vcs_info
setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true

zstyle ':vcs_info:*' stagedstr '%F{green}A%f'
zstyle ':vcs_info:*' unstagedstr '%F{red}M%f'
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-unpushed git-status-bracket

# Format strings:
# - When in normal mode: [branch][status] (status only shown if present)
# - When in action mode: [branch+action][status]
# %u = unstaged, %c = staged, %m = misc (untracked via hook)
zstyle ':vcs_info:git:*' formats '[%b]%m'
zstyle ':vcs_info:git:*' actionformats '[%b+%a]%m'

# Hook function to check for untracked files
+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
     git status --porcelain | grep -q '^?? ' 2> /dev/null ; then
    hook_com[unstaged]+='%F{blue}??%f'
  fi
}

# Hook function to check for unpushed commits
+vi-git-unpushed() {
  local ahead
  ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
  if [[ -n $ahead ]] && [[ $ahead -gt 0 ]]; then
    hook_com[unstaged]+='%F{magenta}↑%f'
  fi
}

# Hook function to wrap status in brackets if any status exists
# Order: staged (A), unstaged (M), untracked (??), unpushed (↑) - matching gs output
+vi-git-status-bracket() {
  if [[ -n ${hook_com[unstaged]} ]] || [[ -n ${hook_com[staged]} ]]; then
    hook_com[misc]="[${hook_com[staged]}${hook_com[unstaged]}]"
  fi
}

# Fancy precmd: all git checks (staged, unstaged, untracked, unpushed)
precmd_fancy() {
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-unpushed git-status-bracket
  vcs_info
}

# Minimal precmd: only branch + unpushed commits (fast for large/mounted repos)
precmd_minimal() {
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*+set-message:*' hooks git-unpushed git-status-bracket
  vcs_info
}

PROMPT='%F{magenta}${username}${hostname}%F{blue}%.%F{cyan}${vcs_info_msg_0_}%f%# '

local fancy_left=$PROMPT
local fancy_right=$RPROMPT

fancy_prompt() {
  precmd_functions=(precmd_fancy)
  export PROMPT=$fancy_left
  export RPROMPT=$fancy_right
}

minimal_prompt() {
  precmd_functions=(precmd_minimal)
  export PROMPT=$fancy_left
  export RPROMPT=$fancy_right
}

simple_prompt() {
  precmd_functions=()
  export PROMPT='%# '
  export RPROMPT=''
}

# Start with fancy prompt by default
precmd_functions=(precmd_fancy)
