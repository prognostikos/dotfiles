local hostname="%m:"
local username=''

[ -z $SSH_TTY ] && hostname=''
[ "$USER" != rohrer ] && username="%n@"

setopt prompt_subst

# Git prompt segment: [branch(+action)][A M ?? ↑]
# Order: staged (A), unstaged (M), untracked (??), unpushed (↑) - matching gs output
#
# Uses a single `git status --porcelain=v2 --branch` (one worktree scan) instead of
# vcs_info's several diff/status/rev-list calls. Pair with core.fsmonitor and
# core.untrackedCache (see git/gitconfig-darwin.symlink) for large repos.
#
# $1 = full    -> branch, action, staged, unstaged, untracked, unpushed
# $1 = minimal -> branch, action, unpushed (no worktree scan; for huge/mounted repos)
_git_prompt_update() {
  git_prompt_info=''

  local gitdir
  gitdir=$(command git rev-parse --git-dir 2>/dev/null) || return

  local branch oid action ahead=0 staged='' unstaged='' untracked='' line

  if [[ $1 == full ]]; then
    for line in "${(@f)$(command git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)}"; do
      case $line in
        '# branch.head '*) branch=${line#\# branch.head } ;;
        '# branch.oid '*)  oid=${line#\# branch.oid } ;;
        '# branch.ab +'*)  ahead=${${line#\# branch.ab +}%% *} ;;
        [12u]' '*)
          [[ ${line[3]} != . ]] && staged=1
          [[ ${line[4]} != . ]] && unstaged=1
          ;;
        '? '*) untracked=1 ;;
      esac
    done
    [[ $branch == '(detached)' ]] && branch=${oid[1,7]}
  else
    branch=$(command git symbolic-ref --short -q HEAD 2>/dev/null) ||
      branch=$(command git rev-parse --short HEAD 2>/dev/null)
    ahead=$(command git rev-list --count @{upstream}..HEAD 2>/dev/null) || ahead=0
  fi

  if [[ -d $gitdir/rebase-merge ]]; then
    action=rebase-i
    branch=${$(<$gitdir/rebase-merge/head-name)#refs/heads/}
  elif [[ -d $gitdir/rebase-apply ]]; then
    if [[ -f $gitdir/rebase-apply/applying ]]; then
      action=am
    else
      action=rebase
      [[ -f $gitdir/rebase-apply/head-name ]] &&
        branch=${$(<$gitdir/rebase-apply/head-name)#refs/heads/}
    fi
  elif [[ -f $gitdir/MERGE_HEAD ]]; then
    action=merge
  elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then
    action=cherry
  elif [[ -f $gitdir/REVERT_HEAD ]]; then
    action=revert
  elif [[ -f $gitdir/BISECT_LOG ]]; then
    action=bisect
  fi

  local status_str=''
  [[ -n $staged ]] && status_str+='%F{green}A%f'
  [[ -n $unstaged ]] && status_str+='%F{red}M%f'
  [[ -n $untracked ]] && status_str+='%F{blue}??%f'
  (( ahead > 0 )) && status_str+='%F{magenta}↑%f'

  # escape % in branch names so they aren't treated as prompt sequences
  git_prompt_info="[${branch//\%/%%}${action:++$action}]${status_str:+[$status_str]}"
}

# Fancy precmd: all git checks (staged, unstaged, untracked, unpushed)
precmd_fancy() {
  _git_prompt_update full
}

# Minimal precmd: only branch + unpushed commits (fast for large/mounted repos)
precmd_minimal() {
  _git_prompt_update minimal
}

# Tmux precmd: no git info needed (tmux status bar shows full git status)
precmd_tmux() {
  # No git info needed - git status is in tmux status bar
  :
}

# Swap the active prompt hook without dropping hooks added elsewhere (e.g. _reset_cursor)
_set_prompt_precmd() {
  precmd_functions=($@ ${precmd_functions:#precmd_*})
}

PROMPT='%F{magenta}${username}${hostname}%F{blue}%.%F{cyan}${git_prompt_info}%f%# '

local fancy_left=$PROMPT
local fancy_right=$RPROMPT
local tmux_left='%F{magenta}${username}${hostname}%F{blue}%.%f%# '

fancy_prompt() {
  _set_prompt_precmd precmd_fancy
  export PROMPT=$fancy_left
  export RPROMPT=$fancy_right
}

minimal_prompt() {
  _set_prompt_precmd precmd_minimal
  export PROMPT=$fancy_left
  export RPROMPT=$fancy_right
}

simple_prompt() {
  _set_prompt_precmd
  export PROMPT='%# '
  export RPROMPT=''
}

# Start with fancy prompt by default, or simplified prompt if in tmux
if [[ -n "$TMUX" ]]; then
  _set_prompt_precmd precmd_tmux
  export PROMPT=$tmux_left
  export RPROMPT=$fancy_right
else
  _set_prompt_precmd precmd_fancy
fi
