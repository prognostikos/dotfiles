# Originally from https://github.com/garybernhardt/dotfiles/blob/master/.githelpers
#
# Log output:
#
# * 51c333e    (12 days)    <Gary Bernhardt>   add vim-eunuch
#
# The time massaging regexes start with ^[^<]* because that ensures that they
# only operate before the first "<". That "<" will be the beginning of the
# author name, ensuring that we don't destroy anything in the commit message
# that looks like time.
#
# The log format uses } characters between each field, and `column` is later
# used to split on them. A } in the commit subject or any other field will
# break this.

HASH="%C(yellow)%h%Creset"
RELATIVE_TIME="%C(cyan)(%ar)%Creset"
AUTHOR="%C(blue)<%an>%Creset"
REFS="%C(magenta)%d%Creset"
SUBJECT="%s"

FORMAT="$HASH}$RELATIVE_TIME}$AUTHOR}$REFS $SUBJECT"

ANSI_RED='\033[31m'
ANSI_RESET='\033[0m'

show_git_head() {
    pretty_git_log -1
    git show -p --pretty="tformat:"
}

pretty_git_log() {
    git log --graph --pretty="tformat:${FORMAT}" $* |
        # Replace (2 years ago) with (2 years)
        sed -Ee 's/(^[^<]*) ago\)/\1)/' |
        # Replace (2 years, 5 months) with (2 years)
        sed -Ee 's/(^[^<]*), [[:digit:]]+ .*months?\)/\1)/' |
        # Line columns up based on } delimiter
        column -s '}' -t |
        # Color merge commits specially
        sed -Ee "s/(Merge branch .* into .*$)/$(printf $ANSI_RED)\1$(printf $ANSI_RESET)/" |
        # Page only if we need to
        less -FXRS
}

# don't use git ls-files when tab-completing in a git repo
__git_files() {
    _wanted files expl 'local files' _files
}

gs() {
  git status -sb 2>/dev/null

  if [ $? -ne 0 ]; then
    (>&2 echo "not a Git repo - listing files")
    ls
  fi
}
