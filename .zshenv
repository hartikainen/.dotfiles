#!/usr/bin/env zsh

# No need to export anything here, as `.zshenv` is sourced for every shell
# (unless invoked as `zsh -f`).

# These could also be assigned on export in `.zshrc` but we prefer assigning
# this early. These get exported in `.zshrc`.
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

# `ZDOTDIR` has to be set here to be able to store other zsh dotfiles outside of
# `HOME`.
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
