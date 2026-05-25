#!/bin/bash

# TODO(hartikainen): Figure what the right way to set these is for different
# shell types (e.g. interactive vs. non-interactive).
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

# Root of the dotfiles checkout. Used by the files sourced below to locate
# `setup/utils.sh`. Defaults to whichever directory `${HOME}/.bashrc` is a
# symlink into (which is how `create_symbolic_links.sh` wires it up),
# falling back to `${HOME}/.dotfiles`. Override by exporting `DOTFILES_DIR`
# from your environment.
if [ -z "${DOTFILES_DIR:-}" ] && [ -L "${HOME}/.bashrc" ]; then
    DOTFILES_DIR="$(dirname "$(readlink "${HOME}/.bashrc")")"
fi
: "${DOTFILES_DIR:=${HOME}/.dotfiles}"

# Silence macos bash deprecation warning. See
# https://support.apple.com/en-us/HT208050/ for more information.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Return if not running interactively.
case $- in
    *i*) ;;
    *) return;;
esac

# Set the cursor to a block style
echo -ne "\e[2 q"

# Only variables needed by external commands or non-interactive sub shells
# should be exported.
export XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME

export SHELL_SESSION_DIR="${XDG_STATE_HOME}/bash/sessions"
export SHELL_SESSION_FILE="${SHELL_SESSION_DIR}/${TERM_SESSION_ID}"

command -v fzf &> /dev/null && eval "$(fzf --bash)"



source_files() {

    declare -r -a FILES_TO_SOURCE=(
        "${XDG_CONFIG_HOME}/bash/aliases"
        "${XDG_CONFIG_HOME}/bash/autocomplete"
        "${XDG_CONFIG_HOME}/bash/exports"
        "${XDG_CONFIG_HOME}/bash/functions"
        "${XDG_CONFIG_HOME}/bash/colors"

        "${XDG_CONFIG_HOME}/bash/options"

        # For local settings that should
        # not be under version control.
        "${XDG_CONFIG_HOME}/bash/local"
    )

    . "${DOTFILES_DIR}/setup/utils.sh"

    for file in "${FILES_TO_SOURCE[@]}"; do
        [ -r "${file}" ] && source "${file}"
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_files
unset -f source_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/oh-my-posh.toml)"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear


. "$HOME/.local/share/../bin/env"
