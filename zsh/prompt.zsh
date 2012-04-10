local smiley="%(?,%{$fg[cyan]%}☺%{$reset_color%},%{$fg[magenta]%}☹%{$reset_color%})"

PROMPT='%{$fg[cyan]%}%~ %{$reset_color%}
${smiley} %{$reset_color%}'

RPROMPT='%{$fg[magenta]%} $(rbenv version-name)$(git-cwd-info.rb)%{$reset_color%}'
