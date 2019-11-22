#!/bin/bash

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# if [ -d "${HOME}/.bashrc.d" ]; then
#     for file in $(/bin/ls "${HOME}/.bashrc.d/*.bashrc"); do
#         source $file;
#     done
# fi

source_files() {

    declare -r -a FILES_TO_SOURCE=(
        ".bashrc.d/.bash_aliases"
        ".bashrc.d/.bash_autocomplete"
        ".bashrc.d/.bash_exports"
        ".bashrc.d/.bash_functions"
        ".bashrc.d/.bash_colors"

        ".bashrc.d/.bash_options"
        ".bashrc.d/.bash_prompt"

        # For local settings that should
        # not be under version control.
        ".bash.local"
    )

    declare -r CURRENT_DIRECTORY="$(pwd)"

    cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" \
        && . "../setup/utils.sh"

    cd "${CURRENT_DIRECTORY}"

    for f in ${FILES_TO_SOURCE[*]}; do

        file="${HOME}/${f}"

        [ -r "${file}" ] \
            && . "${file}"

    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
source_files
unset -f source_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
