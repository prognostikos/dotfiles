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

export RUBY_GC_MALLOC_LIMIT=59000000
export RUBY_HEAP_MIN_SLOTS=600000
export RUBY_HEAP_FREE_MIN=100000

[ -d ~/c/go ] && export GOPATH=~/c/go
[ -d ~/javaclasses ] && export CLASSPATH=$CLASSPATH:~/javaclasses:.

export VAGRANT_DEFAULT_PROVIDER=vmware_fusion
