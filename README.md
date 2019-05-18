# These are my dotfiles. There are many like them but these are mine.

Concept/layout stolen from [@holman's dotfiles](https://github.com/holman/dotfiles)

## Installation

    $ git clone --recursive https://github.com/prognostikos/dotfiles.git ~/.dotfiles
    $ cd ~/.dotfiles
    $ ./script/setup

## Layout

- **bin/**: Anything in `bin/` will get added to the beginning of your `$PATH`
- **<dir>/\*.zsh**: Any files ending in `.zsh` get loaded into your
  zsh environment.
- **<dir>/\*.bash**: Any files ending in `.bash` get loaded into your
  bash environment.
- **<dir>/aliases**: Any files called `aliases` get loaded into
  both your bash and zsh environments.
- **<dir>/\*.symlink**: Any files or directories ending in `*.symlink` 
  get symlinked into your `$HOME`.
- **<dir>/completion.sh**: Any files called `completion.sh` get loaded
  last so that they get loaded after we set up zsh autocomplete functions.
