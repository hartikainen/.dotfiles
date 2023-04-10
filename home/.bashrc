#!/bin/bash

# TODO(hartikainen): Figure what the right way to set these is for different
# shell types (e.g. interactive vs. non-interactive).
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

# Enable `conda`-command.
__conda_setup="$("${HOME}/conda/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    echo 'Unable to provide `conda` command.'
fi
unset __conda_setup

# Return if not running interactively.
case $- in
    *i*) ;;
    *) return;;
esac

# Only variables needed by external commands or non-interactive sub shells
# should be exported.
export XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME
export EDITOR="emacs" VISUAL="emacs"

export SHELL_SESSION_DIR="${XDG_STATE_HOME}/bash/sessions"
export SHELL_SESSION_FILE="${SHELL_SESSION_DIR}/${TERM_SESSION_ID}"

[ -f "${XDG_CONFIG_HOME}/fzf/fzf.sh" ] && source "${XDG_CONFIG_HOME}/fzf/fzf.sh"
[ -f "${XDG_CONFIG_HOME}/fzf/fzf.bash" ] && source "${XDG_CONFIG_HOME}/fzf/fzf.bash"


source_files() {

    declare -r -a FILES_TO_SOURCE=(
        "${XDG_CONFIG_HOME}/bash/aliases"
        "${XDG_CONFIG_HOME}/bash/autocomplete"
        "${XDG_CONFIG_HOME}/bash/exports"
        "${XDG_CONFIG_HOME}/bash/functions"
        "${XDG_CONFIG_HOME}/bash/colors"

        "${XDG_CONFIG_HOME}/bash/options"
        "${XDG_CONFIG_HOME}/bash/prompt"

        # For local settings that should
        # not be under version control.
        "${XDG_CONFIG_HOME}/bash/local"
    )

    local DOTFILES_ROOT="$(realpath "${XDG_CONFIG_HOME}/../..")"
    . "${DOTFILES_ROOT}/setup/utils.sh"

    for file in "${FILES_TO_SOURCE[@]}"; do
        [ -r "${file}" ] && source "${file}"
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_files
unset -f source_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
