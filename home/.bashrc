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

source_bash_files() {

    declare -r CURRENT_DIRECTORY="$(pwd)"

    declare -r -a FILES_TO_SOURCE=(
        ".bashrc.d/.bash_aliases"
        ".bashrc.d/.bash_autocomplete"
        ".bashrc.d/.bash_exports"
        ".bashrc.d/.bash_functions"
        ".bashrc.d/.bash_options"
        ".bashrc.d/.bash_prompt"
        ".bash.local"  # For local settings that should
                                  # not be under version control.
        ".bashrc.d/.bash_colors"
    )

    local file=""
    local i=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" \
        && . "../setup/utils.sh"

    # shellcheck disable=SC2034
    declare -r OS="$(get_os)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    for i in ${!FILES_TO_SOURCE[*]}; do

        file="${HOME}/${FILES_TO_SOURCE[$i]}"

        [ -r "$file" ] \
            && . "$file"

    done

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    cd "$CURRENT_DIRECTORY"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_bash_files
unset -f source_bash_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
