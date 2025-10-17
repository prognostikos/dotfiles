local hostname="%m:"
local username=''

[ -z $SSH_TTY ] && hostname=''
[ "$USER" != rohrer ] && username="%n@"

PROMPT='%{$fg[magenta]%}${username}${hostname}%{$fg[blue]%}%.%{$fg[cyan]%}$(git-cwd-info)%{$reset_color%}%# '

local fancy_left=$PROMPT
local fancy_right=$RPROMPT

fancy_prompt(){ export PROMPT=$fancy_left; export RPROMPT=$fancy_right }
simple_prompt(){ export PROMPT='$ '; export RPROMPT='' }
