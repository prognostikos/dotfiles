# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository that manages shell configurations, utilities, and application settings. The setup uses a convention-based approach where files in topic-specific directories are automatically sourced or symlinked based on their naming patterns.

## Key Commands

### Setup and Installation
- `./script/setup` - Install dotfiles by symlinking `*.symlink` files to `$HOME` (backs up existing files)
- Initial setup: `git clone --recursive https://github.com/prognostikos/dotfiles.git ~/.dotfiles`

### Common Utilities (in bin/)
- `tat [session_name]` - Attach to or create a tmux session (defaults to current directory name)
- `muxrails` - Set up a Rails-oriented tmux workspace with editor, console, db, and server windows
- `git-pr` - Open a GitHub compare page for the current branch
- `prco <pr_number>` - Checkout a GitHub pull request locally (via gh CLI)
- `bump-key-expiration <key_id> [expiration]` - Update GPG key expiration and publish to keyservers
- `cleanup-keys` - Clean up GPG public keys
- `op-pinentry` - GPG pinentry program that reads PIN from 1Password

### Testing & Validation
No automated test suite. Changes should be manually tested by:
1. Sourcing the modified shell files: `source ~/.zshrc`
2. Testing specific functions or aliases in a new shell session
3. Lint shell scripts with: `shellcheck bin/<script-name>`

## Architecture

### File Organization Conventions

The repository is organized into topic directories (git/, zsh/, docker/, etc.). Files are automatically loaded based on these patterns:

1. **`*.symlink`** - Symlinked to `$HOME` as dotfiles (e.g., `git/gitconfig.symlink` → `~/.gitconfig`)
2. **`*.zsh`** - Auto-loaded into zsh environment (sourced in `~/.zshrc`)
3. **`*.bash`** - Auto-loaded into bash environment
4. **`aliases`** - Loaded into both bash and zsh
5. **`completion.sh`** - Loaded last for shell completion setup
6. **`bin/`** - Added to beginning of `$PATH` for custom commands

### Shell Configuration Flow (zsh/zshrc.symlink)

1. Environment setup (EDITOR, LANG, git PS1 settings)
2. PATH manipulation (Homebrew, rbenv, direnv, mise, Go, dotfiles bin/)
3. Load all `**/*.zsh` files
4. Load all `**/aliases` files
5. Set shell options (AUTO_PUSHD, emacs keybindings)
6. Initialize completions (compinit with daily caching)
7. Load all `**/completion.sh` files
8. Setup GPG agent

### Git Configuration

- Commits are GPG-signed by default
- Merge strategy: fast-forward only, zdiff3 conflict style
- Rebase: auto-squash and auto-stash enabled
- Branches sorted by commit date
- Pull requests use rebase
- Submodules recurse automatically

### Tool Integration

- **Editor**: nvim (if available), falls back to vim
- **Shell**: zsh with custom prompt and history substring search
- **Version managers**: rbenv, direnv, mise
- **Package manager**: Homebrew (ARM at /opt/homebrew, Intel at /usr/local)
- **GPG**: Configured with pinentry via 1Password (OP_GPG_PIN env var)
- **Mail**: mbsync, msmtp, mutt, notmuch
- **Tmux**: Custom keybindings and session management via `tat`

## Shell Script Conventions

When writing or modifying shell scripts in `bin/` or elsewhere:

- **Shebang**: Use `#!/bin/bash` (default to bash)
- **Error handling**: Start scripts with `set -euo pipefail`
- **Indentation**: Use 2 spaces (no tabs)
- **Naming**: Use kebab-case (e.g., `git-cleanup`, `bump-key-expiration`)
- **File extension**: No suffix (scripts should not have `.sh` extension)
- **Arguments**: If script takes arguments, include a `usage()` function
- **Linting**: All scripts must pass `shellcheck` validation
- **Permissions**: Make scripts executable with `chmod +x`

## Important Implementation Details

### Adding New Scripts to bin/

Scripts in `bin/` are automatically available in PATH. Make them executable: `chmod +x bin/scriptname`

### Adding New Shell Configurations

- For zsh: Create `<topic>/<name>.zsh`
- For aliases: Create or edit `<topic>/aliases`
- For completions: Create `<topic>/completion.sh`
- For dotfile configs: Create `<topic>/<name>.symlink` (symlinks are managed by user)

### GPG Key Management

GPG keys are managed with 1Password integration:
- `OP_GPG_PIN` environment variable must point to 1Password vault item
- `op-pinentry` script integrates with GPG agent
- Keys should be regularly refreshed via `bump-key-expiration`
