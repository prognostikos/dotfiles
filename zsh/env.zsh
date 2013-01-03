export PATH=$HOME/.rbenv/bin:/usr/local/heroku/bin:/usr/local/share/npm/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/X11/bin:/usr/local/git/bin
eval "$(rbenv init -)"
export PATH=./bin:$HOME/.dotfiles/bin:$PATH

export EDITOR=vim
export LANG=en_US.UTF-8
export CLICOLOR=true
export CLASSPATH=$CLASSPATH:~/javaclasses:.
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export JRUBY_OPTS=--1.9

# https://gist.github.com/1688857
export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_FREE_MIN=500000
export RUBY_HEAP_MIN_SLOTS=40000
