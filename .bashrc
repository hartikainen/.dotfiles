#!/bin/bash
#
# ~/.bashrc: read by bash when invoked as an interactive non-login shell
# (e.g. opening a new terminal pane after the first), and indirectly by
# login shells via `~/.bash_profile`. Keep this file scoped to
# interactive setup only — env vars, PATH, and anything that should be
# visible to non-interactive shells belong in `~/.profile`.

# Return if not running interactively. Anything below this line is
# allowed to assume an interactive terminal.
case $- in
    *i*) ;;
    *) return;;
esac

# Safety net for `bash -i` invoked from a script (which doesn't go
# through `~/.bash_profile`): pull in `~/.profile` once so XDG_*,
# DOTFILES_DIR, and `~/.local/bin/env` are still set.
if [ -z "${DOTFILES_DIR:-}" ] && [ -f "${HOME}/.profile" ]; then
    . "${HOME}/.profile"
fi

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

if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh > /dev/null; then
    eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/oh-my-posh.toml)"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
