#!/usr/bin/env zsh
#
# ~/.zshenv: sourced for every zsh invocation — login, interactive,
# non-interactive scripts, and `zsh -c '...'` alike (unless invoked as
# `zsh -f`). It's the only zsh startup file guaranteed to run before
# `.zprofile` or any command spawned from a non-interactive shell, so
# variables that must be visible to external processes belong here.
#
# Keep this file small and side-effect free; expensive interactive setup
# belongs in `.zshrc`.

# `ZDOTDIR` depends on the shared environment for every shell invocation.
[ -f "${HOME}/.profile" ] && . "${HOME}/.profile"

# `ZDOTDIR` has to be set in `.zshenv` so zsh can find the rest of its
# dotfiles outside of `$HOME`. Exported so child zsh shells inherit it.
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
