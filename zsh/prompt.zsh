local smiley="%(?,%{$fg[cyan]%}☺%{$reset_color%},%{$fg[magenta]%}☹%{$reset_color%})"
local hostname="%m:"
local username=''

if [ -z $SSH_TTY ]; then
  hostname=''
fi

if [ 'rohrer' != $USER ]; then
  username="%n@"
fi

fancy_left='%{$fg[cyan]%}${username}${hostname}%~ %{$reset_color%}
${smiley} %{$reset_color%}'
fancy_left=$PROMPT

RPROMPT=' %{$fg[magenta]%}$(rbenv version-name)%{$reset_color%} %{$fg[blue]%}$(git-cwd-info)%{$reset_color%}'
fancy_right=$RPROMPT

fancy_prompt(){ export PROMPT=$fancy_left; export RPROMPT=$fancy_right}
simple_prompt(){ export PROMPT='$ '; export RPROMPT='' }
