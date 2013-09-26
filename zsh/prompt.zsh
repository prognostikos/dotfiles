#local smiley=" %(?,%{$fg[cyan]%}☺%{$reset_color%},%{$fg[magenta]%}☹%{$reset_color%})"
local hostname="%m:"
local username=''

[ -z $SSH_TTY ]       && hostname=''
[ 'rohrer' != $USER ] && username="%n@"

PROMPT='%{$fg[magenta]%}${username}${hostname}%{$fg[blue]%}%.%{$fg[cyan]%}$(git-cwd-info)%{$reset_color%}%# '
# RPROMPT='%{$fg[magenta]%} $(rbenv version-name)%{$reset_color%}'

local fancy_left=$PROMPT
local fancy_right=$RPROMPT

fancy_prompt(){ export PROMPT=$fancy_left; export RPROMPT=$fancy_right}
simple_prompt(){ export PROMPT='$ '; export RPROMPT='' }
