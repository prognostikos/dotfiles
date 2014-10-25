if command -v brew > /dev/null ; then
  export PATH="$PATH:/usr/local/lib/node_modules"
  source $(brew --prefix nvm)/nvm.sh
fi

if [ -d ~/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - zsh --no-rehash)"
fi

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

export TZ=Europe/Copenhagen
