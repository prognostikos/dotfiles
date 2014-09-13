export PATH=/opt/X11/bin:/usr/local/bin:/usr/local/sbin:$PATH
export PATH=/usr/local/heroku/bin:/usr/local/share/npm/bin:~/Library/Python/2.7/bin:$PATH

[ -d ~/.rbenv ] && eval "$(rbenv init -)"

export PATH=.git/safe/../../bin:~/.dotfiles/bin:$PATH

[ -d ~/c/bn/sub/bin ] && export PATH=~/c/bn/sub/bin:$PATH

export EDITOR=vim
export LANG=en_US.UTF-8
export CLICOLOR=true

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

[ -d ~/c/go ] && export GOPATH=~/c/go; export PATH=$PATH:$GOPATH/bin
[ -d ~/javaclasses ] && export CLASSPATH=$CLASSPATH:~/javaclasses:.

export VAGRANT_DEFAULT_PROVIDER=vmware_fusion

export TZ=Europe/Copenhagen
